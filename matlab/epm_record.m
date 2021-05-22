% epm_record obj
% 
classdef epm_record< handle
   properties 
       epm
       record
   end
   
   properties (Access=private)
        epm_signal
        delay
   end
   
   methods
        function obj=epm_record(epm,record)
          obj.record=record;
          obj.epm=epm;
       end
       
        function assignSignal(obj,delay)
          obj.delay=delay;
          fs=obj.record.signal.fs;
          trace=obj.record.signal.trace;
          epm_trace_idx=floor((obj.epm.time+delay)*fs)+1;
          if epm_trace_idx >length(trace)
            warning('time exceed, complete the trace with last point')
            epm_trace_idx(epm_trace_idx>length(trace))=length(trace);
          end
        epm_trace_idx=epm_trace_idx(obj.epm.pass==1);
        obj.epm_signal=trace(epm_trace_idx);
        scatter(obj.epm.position(:,1),obj.epm.position(:,2),[],obj.epm_signal,'filled')
        colormap('jet')
        end
       
        function findTrace(obj,n_table,eventname,roi)
            curr_table=obj.record.event.tables{n_table};
            curr_event=curr_table(string(curr_table.eventname)==eventname,:);
            [nrow,~]=size(curr_event);
            time=obj.epm.time(obj.epm.pass);
            passed=zeros(length(obj.epm_signal),1);
            if roi(1)<1
                roi(1)=1;
            end
            if roi(2)>nrow || isequal(roi(2),inf)
                roi(2)=nrow;
            end
            for i =roi(1):roi(2)
                passed(time>(curr_event.start(i)+obj.delay) & time<(curr_event.end(i)+obj.delay))=1;
            end
            scatter(obj.epm.position(passed==1,1),obj.epm.position(passed==1,2),6,obj.epm_signal(passed==1),'filled')
            xlim([-30 30])
            ylim([-30 30])
            colormap('jet')
        end
        
        function curr_trace=transTrace(obj,n_table,eventname)
            curr_table=obj.record.event.tables{n_table};
            curr_event=curr_table(string(curr_table.eventname)==eventname,:);
            [nrow,~]=size(curr_event);
            time=obj.epm.time(obj.epm.pass==1);
            curr_trace=cell(nrow,1);
            dff=(obj.epm_signal-mean(obj.epm_signal))./mean(obj.epm_signal);
            for i =1:nrow
                select_idx=time>(curr_event.start(i)+obj.delay) & time<(curr_event.end(i)+obj.delay);
                size(obj.epm.position(select_idx,:))
                size(dff(select_idx))
                curr_trace{i}=[time(select_idx),obj.epm.position(select_idx,:),dff(select_idx)'];
            end
        end
   end
   methods (Access=private)
        
   end
end