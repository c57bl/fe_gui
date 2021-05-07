classdef mice_card < handle

    properties (Access=public)
        record
        pointer
        event_trace
    end
    
    properties (Access=private)
        curr_filter
        curr_cover
    end
    methods (Access=private)
        function event_filter(obj)
            obj.curr_filter=event_filter;
            obj.curr_filter=obj.curr_filter.datain(obj.mice_record,obj.signal_detrend);
            addlistener(obj.curr_filter,'confirmed',@obj.event_confirm);
        end
        
        function event_confirm(obj,varargin)
            % auto confirm selected event
            obj.event_select=obj.curr_filter.selected;
            event_start=obj.mice_record.event.start(find(obj.event_select==1));
            event_end=obj.mice_record.event.stop(find(obj.event_select==1));
            obj.selected_event=[event_start',event_end'];
        end
    end
    methods (Access=public)
        function obj =mice_card(mice_record_obj,pointer_obj)
            obj.record=mice_record_obj;
            obj.pointer=pointer_obj;
        end
        
        function show(obj,window)
            
        end
        
        function get_event_trace(obj)
            trace_num=obj.pointer.parameter.trace_num;
            event_value=obj.pointer.parameter.event_value;
            event_focus=obj.record.coldata(:,trace_num)==...
                event_value;
            %% in case start from record begin 
            window=floor(obj.pointer.parameter.window_signal*obj.record.signal.fs);
            event_focus=[0;event_focus;0];
            event_focus_idx=[find(diff(event_focus)==(1)),find(diff(event_focus)==(-1))-2];
            event_focus_idx=[event_focus_idx(:,1)+window(1),event_focus_idx(:,2)+window(2)];
            %% filter index 
            trace_num=size(event_focus_idx);
            trace_num=trace_num(1);
            record_length=length(obj.record.signal.trace);
            for i=1:(trace_num-1)
                curr_idx=event_focus_idx(i,:);
                next_idx=event_focus_idx(i+1,:);
                if curr_idx(1)<0 || curr_idx(2)>record_length ||...
                    curr_idx(2)< next_idx(1)
                warning('remove conflict event')
                end
            end
            %% split trace
            trace_num=size(event_focus_idx);
            trace_num=trace_num(1);
            obj.event_trace=cell([trace_num(1) 1]);
            for i=1:trace_num
                curr_idx=event_focus_idx(i,:);
                curr_coldata=obj.record.coldata(curr_idx(1):curr_idx(2),:);
                curr_rowdata=[curr_idx(1),curr_idx(2),curr_idx(2)-curr_idx(1)];
                curr_data=obj.record.signal.trace(curr_idx(1):curr_idx(2));
                curr_event_trace.data=curr_data;
                curr_event_trace.coldata=curr_coldata;
                curr_event_trace.rowdata=curr_rowdata;
                obj.event_trace{i}=curr_event_trace;
            end
        end
    end
end

