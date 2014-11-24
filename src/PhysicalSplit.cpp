
#include <limits>
#include <limits>
#include <sstream>

#include <boost/unordered_map.hpp>
#include <query/Operator.h>
#include <util/Platform.h>
#include <array/Tile.h>
#include <array/TileIteratorAdaptors.h>
#include <system/Sysinfo.h>
#include "SplitSettings.h"

namespace scidb
{
using namespace boost;
using namespace scidb;


/**
 * A wrapper around an open file (or pipe) that may iterate over the data once and split it into blocks, each
 * block containing a number of lines. Returns one block at a time.
 */
class FileSplitter
{
private:
    size_t const _linesPerBlock;
    size_t       _bufferSize;
    vector<char> _buffer;
    char*        _dataStartPos;
    size_t       _dataSize;
    bool         _endOfFile;
    FILE*        _inputFile;
    char         _delimiter;

public:
    FileSplitter(string const& filePath,
                 size_t numLinesPerBlock,
                 size_t bufferSize,
                 char delimiter):
        _linesPerBlock(numLinesPerBlock),
        _bufferSize(bufferSize),
        _buffer(0),
        _dataStartPos(0),
        _dataSize(0),
        _endOfFile(false),
        _inputFile(0),
        _delimiter(delimiter)
    {
        try
        {
            _buffer.resize(_bufferSize);
        }
        catch(...)
        {
            throw SYSTEM_EXCEPTION(SCIDB_SE_INTERNAL, SCIDB_LE_ILLEGAL_OPERATION) << "FileSplitter() cannot allocate memory";
        }
        _inputFile = fopen(filePath.c_str(), "r");
        if (_inputFile == NULL)
        {
            throw SYSTEM_EXCEPTION(SCIDB_SE_INTERNAL, SCIDB_LE_ILLEGAL_OPERATION) << "FileSplitter() cannot open file";
        }
        _dataSize = fread(&_buffer[0], 1, _bufferSize, _inputFile);
        if (_dataSize != _bufferSize)
        {
            _endOfFile= true;
            fclose(_inputFile);
            _inputFile =0;
        }
        _dataStartPos = &_buffer[0];
    }

    ~FileSplitter()
    {
        if(_inputFile!=0)
        {
            fclose(_inputFile);
        }
    }

    char* getBlock(size_t& numCharacters)
    {
        size_t lineCounter = _linesPerBlock;
        char* ch = _dataStartPos;
        numCharacters = 0;
        while (1)
        {
            while (numCharacters < _dataSize && lineCounter != 0)
            {
                if(*ch == _delimiter)
                {
                    lineCounter --;
                }
                ++ch;
                ++numCharacters;
            }
            if(lineCounter == 0 || _endOfFile)
            {
                break;
            }
            else
            {
                ch = eatMoreData(); //careful: this call changes _dataStartPos and _dataSize
            }
        }
        char* res = _dataStartPos;
        _dataStartPos = ch;
        _dataSize = _dataSize - numCharacters;
        return res;
    }

private:
    char* eatMoreData()
    {
        char *bufStart = &_buffer[0];
        if (_dataStartPos != bufStart)   //we have a block of data at the end of the buffer - move it to the beginning
        {
            memmove(bufStart, _dataStartPos, _dataSize);
        }
        else
        {
            if(_dataSize != _bufferSize) //invariant check: entire buffer must be full; double it, and read more
            {
                throw SYSTEM_EXCEPTION(SCIDB_SE_INTERNAL, SCIDB_LE_ILLEGAL_OPERATION) << "FileSplitter()::eatMoreData internal error";
            }
            _bufferSize = _bufferSize * 2;
            try
            {
                _buffer.resize(_bufferSize);
            }
            catch(...)
            {
                throw SYSTEM_EXCEPTION(SCIDB_SE_INTERNAL, SCIDB_LE_ILLEGAL_OPERATION) << "FileSplitter()::eatMoreData cannot allocate memory";
            }
            bufStart = &_buffer[0];
        }
        char *newDataStart = bufStart + _dataSize;
        size_t remainderSize = _bufferSize - _dataSize;
        size_t bytesRead = fread( newDataStart, 1, remainderSize, _inputFile);
        if(bytesRead != remainderSize)
        {
            _endOfFile = true;
            fclose(_inputFile);
            _inputFile =0;
        }
        _dataStartPos = bufStart;
        _dataSize = _dataSize + bytesRead;
        return newDataStart;
    }
};


class FileSplitArray : public SinglePassArray
{
private:
    typedef SinglePassArray super;
    size_t _rowIndex;
    Address _chunkAddress;
    MemChunk _chunk;
    weak_ptr<Query> _query;
    FileSplitter _splitter;
    char*  _buffer;
    size_t _bufferSize;

public:
    FileSplitArray(ArrayDesc const& schema, shared_ptr<Query>& query,
                   string const& filePath, size_t numLinesPerBlock, size_t bufferSize, char delimiter):
        super(schema),
        _rowIndex(0),
        _chunkAddress(0, Coordinates(1,-1)),
        _query(query),
        _splitter(filePath, numLinesPerBlock, bufferSize, delimiter)
    {
        super::setEnforceHorizontalIteration(true);
    }

    virtual ~FileSplitArray()
    {}

    size_t getCurrentRowIndex() const
    {
        return _rowIndex;
    }

    bool moveNext(size_t rowIndex)
    {
        _buffer = _splitter.getBlock(_bufferSize);
        if(_bufferSize > 0)
        {
            ++_rowIndex;
            ++(_chunkAddress.coords[0]);
            return true;
        }
        else
        {
            return false;
        }
    }

    ConstChunk const& getChunk(AttributeID attr, size_t rowIndex)
    {
        _chunk.initialize(this, &super::getArrayDesc(), _chunkAddress, 0);
        shared_ptr<Query> query = Query::getValidQueryPtr(_query);
        shared_ptr<ChunkIterator> chunkIt = _chunk.getIterator(query, ChunkIterator::SEQUENTIAL_WRITE | ChunkIterator::NO_EMPTY_CHECK);
        Value v;
        v.setSize(_bufferSize+1);
        char *d = (char*) v.data();
        memcpy(d, _buffer, _bufferSize);
        d[_bufferSize] = 0;
        chunkIt->writeItem(v);
        chunkIt->flush();
        return _chunk;
    }
};

class PhysicalSplit : public PhysicalOperator
{
public:
    PhysicalSplit(std::string const& logicalName,
                     std::string const& physicalName,
                     Parameters const& parameters,
                     ArrayDesc const& schema):
        PhysicalOperator(logicalName, physicalName, parameters, schema)
    {}

    virtual bool changesDistribution(std::vector<ArrayDesc> const&) const
    {
        return true;
    }

    virtual ArrayDistribution getOutputDistribution(std::vector<ArrayDistribution> const&, std::vector<ArrayDesc> const&) const
    {
        //TODO: change me when input from different instances or parallel is allowed.
        //see PhysicalInput.cpp
        return ArrayDistribution(psLocalInstance,
                                 boost::shared_ptr<DistributionMapper>(),
                                 0);
    }

    boost::shared_ptr< Array> execute(std::vector< boost::shared_ptr< Array> >& inputArrays, boost::shared_ptr<Query> query)
    {
        SplitSettings settings (_parameters, false, query);
        if (settings.getSourceInstanceId() != 0)
        {
            throw SYSTEM_EXCEPTION(SCIDB_SE_INTERNAL, SCIDB_LE_ILLEGAL_OPERATION) << "PhysicalSplit::execute internal error";
        }
        if(query->getInstanceID() == 0)
        {
            shared_ptr<Array> result = shared_ptr<FileSplitArray>(new FileSplitArray(_schema,
                                                                                     query,
                                                                                     settings.getInputFilePath(),
                                                                                     settings.getLinesPerChunk(),
                                                                                     settings.getBufferSize(),
                                                                                     settings.getDelimiter()));
            return result;
        }
        else
        {
            shared_ptr<Array> result = boost::shared_ptr<MemArray>(new MemArray(_schema,query));
            return result;
        }
    }
};

REGISTER_PHYSICAL_OPERATOR_FACTORY(PhysicalSplit, "split", "PhysicalSplit");


} // end namespace scidb
