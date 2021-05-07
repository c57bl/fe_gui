classdef mice_record<handle
    properties
        mice
        event
        signal
        coldata
    end     
    properties(Access=private)
        curr_selected_event
        curr_filter
    end
    methods
        function obj = mice_record(mice,mice_event,mice_signal)
            obj.mice=mice;
            obj.event=mice_event;
            obj.signal=mice_signal;
            obj.coldata=obj.get_coldata(mice_event.tables);
        end
        function output=trans_matrix(obj,window,table_num,eventname,anchor)
            trace_num=table_num;
            current_table=obj.event.tables{trace_num};
            current_table=current_table(current_table.selected==true,:);
            % selected rows
            selected_idx=cellfun(@(x) isequal(x,eventname),current_table.eventname);
            current_table=current_table(selected_idx==1,:);
            [nrow,~]=size(current_table);
            if nrow>0
            current_table=[current_table,table((current_table.end-current_table.start)*obj.signal.fs,'VariableNames',{'event_duration'})];
            %% in case start from record begin 
            window=floor(window*obj.signal.fs);
            event_focus_idx=[floor(current_table.start*obj.signal.fs)+1,floor(current_table.end*obj.signal.fs)];
            switch anchor
                case 'start'
                     event_focus_idx=[event_focus_idx(:,1)+window(1),event_focus_idx(:,1)+window(2)];
                case 'end'
                    event_focus_idx=[event_focus_idx(:,2)+window(1),event_focus_idx(:,2)+window(2)];
            end
            %% filter index 
            trace_num=size(event_focus_idx);
            trace_num=trace_num(1);
            record_length=length(obj.signal.trace);
            passed_idx=ones(trace_num,1);
            for i=1:trace_num
                curr_idx=event_focus_idx(i,:);
               if i<trace_num
                    next_idx=event_focus_idx(i+1,:);
                    if curr_idx(1)<0 || curr_idx(2)>record_length ||...
                        curr_idx(2)> next_idx(1)
                    disp('remove conflict event')
                    passed_idx(i)=0;
                    end
               else 
                    if curr_idx(2)>record_length 
                    disp('remove conflict event')
                    passed_idx(i)=0;
                    end
               end
            end
            % filter table and index
            event_focus_idx=event_focus_idx(passed_idx==1,:);
            current_table=current_table(passed_idx==1,:);
            %% split trace
            trace_num=size(event_focus_idx);
            trace_num=trace_num(1);
            output.matrix=zeros([trace_num,window(2)-window(1)+1]);
            output.coldata=cell(trace_num,1);
            for i=1:trace_num
                curr_idx=event_focus_idx(i,:);
                curr_coldata=obj.coldata(curr_idx(1):curr_idx(2),:);
                curr_rowdata=table(string(obj.mice.mice_id),curr_idx(1),curr_idx(2),curr_idx(2)-curr_idx(1),string(anchor),...
                    -window(1),window(2),'VariableNames',{'id','start_frame','end_frame','trace_length','anchor','pre','after'});
                curr_data=obj.signal.trace(curr_idx(1):curr_idx(2));
                output.matrix(i,:)=curr_data;
                output.coldata{i}=curr_coldata;
                output.rowdata(i,:)=curr_rowdata;
            end
            output.rowdata=[output.rowdata,current_table];
            else
                output=[];
            end
        end  % event based on coldata
        function select_trace(obj,event)
            obj.curr_selected_event=event;
            table_for_select=obj.event.tables{event(1)};
            values=table_for_select.value;
            table_for_select=table_for_select(values==event(2),1:2);
            mice_record_obj.table=table_for_select;
            mice_record_obj.signal=obj.signal;
            mice_record_obj.id=obj.mice.mice_id;
            obj.curr_filter=event_filter();
            obj.curr_filter.datain(mice_record_obj);
            addlistener(obj.curr_filter,'confirmed',@obj.update_coldata);
        end
        function output=trans_snippet(obj,baseline_window,event)
       %% pass signal and baseline window to snippet obj
           % select event
            trace_num=event(1);
            event_value=event(2);
            current_table=obj.event.tables{trace_num};
            current_table=[current_table,table(current_table.end-current_table.start,'VariableNames',{'event_duration'})];
            event_focus=current_table(current_table.value==event_value,:);
            % splice event and signal
            
            signal_snippet(signal,baseline_window)
        end
    end
    methods (Access=private)
        function coldata=get_coldata(obj,tables)
           coldata=zeros(length(obj.signal.trace),obj.event.n_table);
           for i=1:obj.event.n_table
              curr_table=tables{i};
              table_size=size(curr_table);
              start_idx=floor(curr_table.start*obj.signal.fs)+1;
              end_idx=floor(curr_table.end*obj.signal.fs)+1;
              for ii=1:table_size(1)
                  coldata(start_idx(ii):end_idx(ii),i)=curr_table.value(ii);
              end
           end
        end   
        function update_coldata(obj,~,~)
            curr_event=obj.curr_selected_event;
            selected=obj.curr_filter.selected;
            table_for_select=obj.event.tables{curr_event(1)};
            values=table_for_select.value;
            table_selected=table_for_select(values==curr_event(2),:);
            table_non_select=table_for_select(values~=curr_event(2),:);
            new_table=[table_non_select;table_selected(selected,:)];
            tables=obj.event.tables;
            tables{curr_event(1)}=new_table;
            obj.coldata=obj.get_coldata(tables);
        end
    end
end

