classdef card_suite < handle
% assume fs  across cards is same
    properties
        cards
        cards_num
    end  
    properties (Access=private)
       parameters
       matrix_mice
    end
    methods (Access=public)
        function obj = card_suite(varargin)
            for i =1:length(varargin)
                obj.cards{i}=varargin{i};
            end
            obj.cards_num=length(varargin);
        end
        function record_matrix=get_matrix(obj,window,table_num,eventname,anchor,varargin) %calculate and aggregate mice
            % splice matrix, matrix_rowdata/coldata from record...
            % trans_matrix output
            for i =1:obj.cards_num
                curr_out=obj.cards{i}.trans_matrix(window,table_num,eventname,anchor);
                curr_matrix=curr_out.matrix;
                curr_rowdata=curr_out.rowdata;
                curr_coldata=curr_out.coldata;
                if i>1
                record_matrix.matrix=[record_matrix.matrix;curr_matrix];
                record_matrix.rowdata=[record_matrix.rowdata;curr_rowdata];
                record_matrix.coldata=[record_matrix.coldata;curr_coldata];
                record_matrix.aggregate.matrix=[record_matrix.aggregate.matrix;mean(curr_matrix,1)];
                record_matrix.aggregate.rowdata=[record_matrix.aggregate.rowdata;...
                    table(curr_rowdata.id(1),curr_rowdata.anchor(1),...
                    curr_rowdata.eventname(1),curr_rowdata.value(1),'VariableNames',{'id','anchor','eventname','value'})];
                else
                record_matrix.matrix=curr_matrix;
                record_matrix.rowdata=curr_rowdata;  
                record_matrix.coldata=curr_coldata;
                record_matrix.aggregate.matrix=mean(curr_matrix,1);
                record_matrix.aggregate.rowdata=table(curr_rowdata.id(1),curr_rowdata.anchor(1),...
                    curr_rowdata.eventname(1),curr_rowdata.value(1),'VariableNames',{'id','anchor','eventname','value'});
                end
            end  
            record_matrix.dff=obj.get_dff(record_matrix.matrix,abs(window(1)/2));
            record_matrix.aggregate.matrix;
            record_matrix.aggregate.dff=obj.get_dff(record_matrix.aggregate.matrix,abs(window(1)/2));
            % rank
            if isempty(varargin)==0
                rank_type=varargin{1};
                record_matrix=obj.rank_matrix(record_matrix,rank_type);
            end
        end
        function show(obj,window,table_num,eventname,anchor,rank_type,varargin)
            if isempty(varargin)
                figure;
                matrix_start=obj.get_matrix(window,table_num,eventname,anchor,rank_type);
                subplot(2,1,1)
                obj.heatmap(matrix_start,window);
                subplot(2,1,2)
                obj.lineplot(obj.dis_matrix(matrix_start.aggregate.dff),window);
            else
                % set axes
                panel=varargin{1};
                ax1 = subplot(2,1,1,'Parent',panel);
                ax2 = subplot(2,1,2,'Parent',panel);
                matrix_start=obj.get_matrix(window,table_num,eventname,anchor,rank_type);
                % heatmap
                obj.heatmap(matrix_start,window,ax1);
                % lineplot
                if obj.cards_num>1
                    obj.lineplot(obj.dis_matrix(matrix_start.aggregate.dff),window,ax2);     
                else
                    obj.lineplot(obj.dis_matrix(matrix_start.dff),window,ax2);
                end
            end
        end
    end
    methods (Access=private)
        function dff=get_dff(obj,matrix,baseline_length)
            fs=obj.cards{1}.signal.fs;
            base_f=mean(matrix(:,1:floor(baseline_length*fs)+1),2);
            dff=(matrix-base_f)./base_f;
        end
        function dis=dis_matrix(~,matrix) % calculate dff related parameters
            dis.mean=mean(matrix,1);
            matrix_size=size(matrix);
            if matrix_size(1)>1
                dis.sd=std(matrix,1);
            else
                dis.sd=0;
            end
            dis.sem=dis.sd/((matrix_size(1))^(1/2));
        end
        function heatmap(obj,matrix,window,varargin)
            if isempty(varargin)
                imagesc(matrix.dff);
                colormap('jet')
                hold on 
                xidx=abs(window(1))*obj.cards{1}.signal.fs;
                matrix_size=size(matrix.dff);
                line([xidx,xidx],[0,matrix_size(1)+1],'Color','black','LineStyle','--')
                yticklabels('')
                xticks(0:250:matrix_size(2))
                xticklabels((0:250:matrix_size(2))/obj.cards{1}.signal.fs)
            else 
                imagesc(varargin{1},matrix.dff);
                colormap(varargin{1},'jet')
                colorbar(varargin{1},'Position', [0.09 0.6 0.025 0.1])
                hold(varargin{1},'on') 
                xidx=abs(window(1))*obj.cards{1}.signal.fs;
                matrix_size=size(matrix.dff);
                line(varargin{1},[xidx,xidx],[0,matrix_size(1)+1],'Color','black','LineStyle','--')
                yticklabels(varargin{1},'')
                xticks(varargin{1},0:250:matrix_size(2))
                xticklabels(varargin{1},(0:250:matrix_size(2))/obj.cards{1}.signal.fs)
                % add event start end
                for i=1:matrix_size(1)
                    current_rowdata=matrix.rowdata(i,:);
                    if isequal(current_rowdata.anchor,'start')
                       line_event=floor(current_rowdata.event_duration)+floor(current_rowdata.pre);
                        if   line_event<=current_rowdata.trace_length
                             line(varargin{1},[line_event,line_event],[i-0.5,i+0.5],'Color','black','LineStyle','-') 
                        end
                    elseif isequal(current_rowdata.anchor,'end')
                       line_event=-floor(current_rowdata.event_duration)+floor(current_rowdata.pre);
                        if   line_event>=0
                             line(varargin{1},[line_event,line_event],[i-0.5,i+0.5],'Color','black','LineStyle','-') 
                        end
                    end
                end
                hold(varargin{1},'off') 
            end
        end
        function lineplot(obj,dff,window,varargin)
            if isempty(varargin)
                trace_x=1:length(dff.mean);
                xidx=abs(window(1))*obj.cards{1}.signal.fs;
                plot(dff.mean,'r')
                hold on
                fill([trace_x,trace_x(end:-1:1)],...
                     [dff.mean-dff.sem,...
                     dff.mean(end:-1:1)+dff.sem(end:-1:1)],'r',...
                    'FaceColor',[1,0.8,0.8],'EdgeColor','none','FaceAlpha',0.5)
                line([xidx,xidx],...
                    [min(dff.mean),max(dff.mean)],...
                    'Color','black','LineStyle','--')
                hold off
                xlim([0 length(trace_x)])
                xticks(0:250:length(trace_x))
                xticklabels(0:250:length(trace_x)/obj.cards{1}.signal.fs)
            else
                trace_x=1:length(dff.mean);
                xidx=abs(window(1))*obj.cards{1}.signal.fs;
                plot(varargin{1},dff.mean,'r')
                hold(varargin{1},'on')
                fill(varargin{1},[trace_x,trace_x(end:-1:1)],...
                     [dff.mean-dff.sem,...
                     dff.mean(end:-1:1)+dff.sem(end:-1:1)],'r',...
                    'FaceColor',[1,0.8,0.8],'EdgeColor','none','FaceAlpha',0.5)
                line(varargin{1},[xidx,xidx],...
                    [min(dff.mean),max(dff.mean)],...
                    'Color','black','LineStyle','--')
                hold(varargin{1},'off')
                xlim(varargin{1},[0 length(trace_x)])
                xticks(varargin{1},0:250:length(trace_x))
                xticklabels(varargin{1},0:250:length(trace_x)/obj.cards{1}.signal.fs)
                hold(varargin{1},'off')
            end
        end
        function matrix=rank_matrix(~,matrix,rank_type)
           rowdata=matrix.rowdata;
           switch rank_type
               case 'Event duration'
                [rowdata,idx]=sortrows(rowdata,'event_duration','ascend');
               case 'Event onset'
                [rowdata,idx]=sortrows(rowdata,'start','ascend');   
           end
           matrix.rowdata=rowdata;
           matrix.matrix=matrix.matrix(idx,:);
           matrix.coldata=matrix.coldata(idx,:);
           matrix.dff=matrix.dff(idx,:);
        end
    end
end

