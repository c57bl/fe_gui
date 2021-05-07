classdef mice_event < handle
    properties
        tables
        n_table
    end
    
    methods
        function  obj=mice_event(table_list)
                obj.n_table=length(table_list);
                obj.tables=cell([obj.n_table,1]);
                for i=1:obj.n_table
                    obj.tables{i}=table_list{i};
                    n_event=unique(table_list{i}.eventname);
                    % join value
                    table_new=table(true(length(n_event),1),n_event,(1:length(n_event))','VariableNames',{'selected','eventname','value'});
                    obj.tables{i}=join(table_list{i},table_new);
                end
        end
    end
    
end

