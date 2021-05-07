classdef mice_signal < handle
   properties
      trace
      fs
      channel
   end
   properties (Access=private)
      trace_raw
      trace_detrend
      detrend_method
      detrend_power
      baseline
   end
   properties (Constant)
       max_n=20
   end
   methods
       function obj=mice_signal(trace,Fs)
            if min(trace)<0
                trace(trace<0)=0;
                warning('negative value treated as 0')
            end
            obj.trace_raw=trace;
            obj.trace=trace;
            obj.fs=Fs;
            obj.channel='raw';
       end
       function detrend(obj,method,power)
            obj.detrend_method=method;
            obj.detrend_power=power;
           % detrend        
            input_trace=obj.trace_raw;
            switch method
                case 'polyfit'
                    n=floor(power/100*obj.max_n)+1;
                    x=0:(length(input_trace)-1);
                    [p,~,mu]=polyfit(x,input_trace',n);
                    curr_baseline=polyval(p,x,[],mu);
                    trace_rb=input_trace'-curr_baseline+mean(curr_baseline);
                case 'spline'
                    % minimum 0.01 windowsize
                    windowsize=(100-power)/100+0.01;
                    % step size was 1/2 window size bu default 
                    stepsize=windowsize/2;
                    x=0:(1/(length(input_trace)-1)):1;length(x);
                    curr_baseline=input_trace-msbackadj(x',input_trace,'WindowSize',windowsize,'StepSize',stepsize);
                    trace_rb=input_trace-curr_baseline+mean(curr_baseline);
            end
            obj.trace=trace_rb;
            obj.baseline=curr_baseline;
            obj.detrend_method=method;
            obj.channel='detrend';
            obj.trace_detrend=trace_rb;
       end
       function plot(obj,varargin)
           if isempty(varargin)
                figure
                subplot(2,1,1)
                plot(obj.trace_raw);
                title('raw trace')
                hold on
                plot(obj.baseline);
                subplot(2,1,2)
                plot(obj.trace_detrend);
                title('detrended')
           else
                plot(varargin{1},obj.trace_raw) 
                hold(varargin{1},'on');
                plot(varargin{1},obj.baseline);
                hold(varargin{1},'off');
           end
       end
       function signal_selected=subset(obj,window)
           selected_trace=obj.trace(window(1):window(2));
           signal_selected=mice_signal(selected_trace,obj.fs);
           signal_selected.channel=obj.channel;
       end
   end
    
end