% epm obj
%   warning: 1.epm obj using cm as unit!
%            2.runNormalize() auto rotate and zoom the position into a standard
%            epm, but require close arm intensity >> open arm, and mice
%            explore across all the close arm! For manual normalize, using
%            runNormalize(epm_teplete).
%   functions: 
%   epm(position,time) position is n*2 matrix,[x_position;y_positon]
%   epm(position,time,event) 
%   epm(position,time,event,templete)
%   setROI() run gui draw polygon to select roi, press enter to finsh
%   setROI(ROI,channel) provide roi to specific channel
%   runFold(direction,equal) fold epm toward specific direction.
%   'direction' :'right-up','left-up','left-down','right-down'

classdef epm < handle
    properties
        position
        time
        channel
        event
        templete
        pass
        splice
    end
    
    properties (Access=private)
       position_raw
       position_normalize
       position_fold
       arm_length=30; % cm
       arm_width=5; % cm
       roi
       position_state
    end
    
    methods
        function obj = epm(position,time,varargin)
                obj.position=position;
                obj.position_raw=position;
                obj.time=time;
                obj.channel="raw";
                obj.pass=ones(length(obj.position(:,1)),1);
           
            if (length(varargin)==1)
        % with event
                obj.event=varargin{1};
            elseif (length(varargin)==2)
        % with event and templete
               obj.event=varargin{1};
               obj.templete=varargin{2};
            end
        end
        
        function runNomalize(obj,varargin)
            % assume close arm intensity > open & close/open degree ==
            % 90,and mice explore all the close arm.
            [~,score,~]=pca(obj.position);
            % recenter
                % find center by far away parts
            [~,i]=sort(score(:,1),'descend');
                % 50 far away points
            center_y=mean(score(i(1:50),2));
            [~,i]=sort(score(:,2),'descend');
                % 50 far away points
            center_x=mean(score(i(1:50),1));
            score=[score(:,1)-center_x,score(:,2)-center_y];
            % zoom
            zoom=30/max([max(score),abs(min(score))]);
            score=score*zoom;
            
            if(abs(min(score(:,1)))<max(score(:,1)))
                score(score(:,1)<=0,1)=score(score(:,1)<=0,1)*obj.arm_length/abs(min(score(:,1)));
            else 
                score(score(:,1)>=0,1)=score(score(:,1)>=0,1)*obj.arm_length/max(score(:,1));
            end
            obj.position_normalize=score;
            scatter(score(:,1),score(:,2))
        end
        
        function runFold(obj,direction)
            if ~isempty(obj.position_normalize)
                obj.switchChannel("normalize")
            switch direction
                case 'top-right'
                    obj.position((obj.position(:,1)<-0 & obj.position(:,2)<-0),:)=...
                        -obj.position((obj.position(:,1)<-0 & obj.position(:,2)<-0),:);
                    obj.position((obj.position(:,1)>0 & obj.position(:,2)<-0),2)=...
                        -obj.position((obj.position(:,1)>-0 & obj.position(:,2)<-0),2);
                    obj.position((obj.position(:,1)<0 & obj.position(:,2)>0),1)=...
                    -obj.position((obj.position(:,1)<0 & obj.position(:,2)>0),1);
                case 'top-left'
                    obj.position((obj.position(:,1)>-0 & obj.position(:,2)<-0),:)=...
                        -obj.position((obj.position(:,1)>-0 & obj.position(:,2)<-0),:);
                    obj.position((obj.position(:,1)>0 & obj.position(:,2)>-0),1)=...
                        -obj.position((obj.position(:,1)>-0 & obj.position(:,2)>-0),1);
                    obj.position((obj.position(:,1)<0 & obj.position(:,2)<0),2)=...
                    -obj.position((obj.position(:,1)<0 & obj.position(:,2)<0),2);
                case 'bottom-left'
                    obj.position((obj.position(:,1)>-0 & obj.position(:,2)>-0),:)=...
                        -obj.position((obj.position(:,1)>-0 & obj.position(:,2)>-0),:);
                    obj.position((obj.position(:,1)>0 & obj.position(:,2)<-0),1)=...
                        -obj.position((obj.position(:,1)>-0 & obj.position(:,2)<-0),1);
                    obj.position((obj.position(:,1)<0 & obj.position(:,2)>0),2)=...
                    -obj.position((obj.position(:,1)<0 & obj.position(:,2)>0),2);
                case 'bottom-right'
                    obj.position((obj.position(:,1)>-0 & obj.position(:,2)>-0),2)=...
                        -obj.position((obj.position(:,1)>-0 & obj.position(:,2)>-0),2);
                    obj.position((obj.position(:,1)<0 & obj.position(:,2)>-0),2)=...
                        -obj.position((obj.position(:,1)<-0 & obj.position(:,2)>-0),2);
                    obj.position((obj.position(:,1)<0 & obj.position(:,2)<0),1)=...
                    -obj.position((obj.position(:,1)<0 & obj.position(:,2)<0),1);
            end
            obj.position_fold=obj.position;
            obj.switchChannel("fold")
            else 
                warning('run runNormalize first')
            end
        end
        
        function setRoi(obj,varargin)
        if (isempty(obj.templete))
            if (isempty(varargin))
                scatter(obj.position(:,1),obj.position(:,2))
                obj.roi.roi=drawpolygon();
                obj.roi.channel=obj.channel;
            else
                obj.roi=varargin{1};
                obj.roi.channel=varargin{2};
            end    
            obj.drop;
            scatter(obj.position(:,1),obj.position(:,2))
        else 
           warning('Roi already exist within templete')
        end
        end
        
        function drop(obj)
           if  isequal(obj.roi.channel,"raw")
               tf = inROI(obj.roi.roi,obj.position_raw(:,1),obj.position_raw(:,2));
               obj.pass(tf==0)=0;
               obj.position=obj.position_raw(obj.pass==1,:);
           else 
               warning('select roi in channel: raw')
           end
        end
        
        function runSplice(obj,varargin)
            if (obj.channel~="normalize")
                warning("please switch to normalize before splice")
            else
                close_idx=abs(obj.position(:,1))>obj.arm_width & ...
                    abs(obj.position(:,2))< obj.arm_width;
                open_idx=abs(obj.position(:,1))<obj.arm_width & ...
                    abs(obj.position(:,2))> obj.arm_width;
                center_idx=abs(obj.position(:,1))<=obj.arm_width & ...
                    abs(obj.position(:,2))<= obj.arm_width;
                obj.splice.close=close_idx;
                obj.splice.open=open_idx;
                obj.splice.center=center_idx;
            end
            
        end
        
        function switchChannel(obj,Channel)
           switch Channel
               case "raw" 
                 obj.position=obj.position_raw;
               case "normalize"
                   if isempty(obj.position_normalize)
                       warning("empty channel, run runNormalize first") 
                   else 
                       obj.position=obj.position_normalize;
                   end
               case "fold"
                   if isempty(obj.position_fold)
                       warning("empty channel, run runFold first")
                   else 
                       obj.position=obj.position_fold;
                   end
           end
           obj.channel=Channel;
        end
    end
    
    methods (Access=private)
            
    end
end
