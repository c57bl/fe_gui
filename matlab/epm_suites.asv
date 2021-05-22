classdef epm_suites<handle
   properties 
       records
       n_record
   end
   
   methods (Access=public)
       
       function obj=epm_suites(epm_records)
           obj.records=epm_records;
           obj.n_record=length(epm_records);
       end
       
       function summary(obj)
           
       end
       function getRecords(obj,n_table,eventname)
           trace=[];
            for i=1:obj.n_record
             trace=[trace;obj.records{i}.transTrace(n_table,eventname)]; %#ok<AGROW>   
            end
       end
   end
   
   methods (Access=private)
       
   end
end