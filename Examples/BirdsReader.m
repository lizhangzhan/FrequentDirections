%    BR = BirdsReader() returns a System object that streams data from
%    the Caltech-UCSD Birds-200-2011.
%
%    This object returns the binary attributes (d = 312) for each sample
%    (n = 11,788). The correctly formatted data file is available here:
%
%    http://www.vision.caltech.edu/visipedia/CUB-200-2011.html
%
%    where the attribute data is a text file 'image_attribute_labels.txt'. 
%    For example, to stream the entire data set:
%
%    BR = BirdsReader('filename','image_attribute_labels.txt');
%    
%    while ~BR.isDone()
%       attributes = BR.step();
%       % do some processing on the current image
%    end
%

classdef BirdsReader < matlab.System & matlab.system.mixin.FiniteSource
   
   properties(Nontunable)
      filename = 'image_attribute_labels.txt'
      formatSpec = '%f %f %f %f %f %*[^\n]';
      nAttributes = 312;
   end
   
   properties
      blockSize = 1      % # of images to read on each iteration
   end
   
   properties(SetAccess = private,GetAccess = public)
      FID = -1           % file id for image data
      
      %nImages            % # of images
      currentCount  % index of current image
   end
   
   methods
      function self = BirdsReader(varargin)
         setProperties(self,nargin,varargin{:});
      end
      
      function set.blockSize(self,blockSize)
         blockSize = fix(blockSize);
         assert(blockSize>0,'blockSize must be >= 1');
         self.blockSize = blockSize;
      end
      
      function goToImage(self,i)
         if self.imageFID == -1
            self.setup();
         end
         assert(i<self.nImages,'index must be <= total number of images');
         nRows = self.nRows;                                  %#ok<*PROPLC>
         nCols = self.nCols;
         spf = nRows*nCols;

         fseek(self.imageFID,4*4 + (i-1)*spf,'bof');
         fseek(self.labelFID,2*4 + (i-1),'bof');
      end
   end
   
   methods(Access = protected)
      function setupImpl(self)
         getWorkingFID(self);
      end
      
      function resetImpl(self)
         goToStartOfData(self);
         self.currentCount = 0;
      end
      
      function attributes = stepImpl(self)
         n = self.nAttributes*self.blockSize;

         data = textscan(self.FID,self.formatSpec,n,...
            'Delimiter','Whitespace','CollectOutput',true,'MultipleDelimsAsOne',1);
         
         id = unique(data{1}(:,1));
         if self.blockSize == 1
            attributes = data{1}(:,3)';
         else
            x = data{1}(:,3);
            attributes = reshape(x,self.nAttributes,numel(x)/self.nAttributes)';
         end

         if ~isempty(id)
            self.currentCount = id(end);
         end
         %self.currentCount = self.currentCount + 1;
      end
      
      function releaseImpl(self)
         fclose(self.FID);
         self.FID = -1;
      end
      
      function tf = isDoneImpl(self)
         tf = logical(feof(self.FID));
      end
   end
   
   methods(Access = private)
      function getWorkingFID(self)
         if(self.FID < 0)
            [self.FID, err] = fopen(self.filename,'rt');
            if ~isempty(err)
               error(message('BirdsReader:fileError',err));
            end
         end
      end
      
      function goToStartOfData(self)
         fseek(self.FID,0,'bof');
      end
   end
end

