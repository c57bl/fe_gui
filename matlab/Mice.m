classdef Mice < handle
    
    properties
        batch
        experiment
        id
    end
    
    properties(Dependent)
        mice_id
    end
    
    methods
        function obj = Mice(batch,experiment,id)
            obj.batch=batch;
            obj.id=id;
            obj.experiment=experiment;
        end
        
        function mice_id =get.mice_id(obj)
            mice_id=[obj.batch,obj.experiment,obj.id];
        end
    end
end
