-- WORK IN PROGRESS (NOT READY FOR USE)
------------------------------------------------------------------------
--[[ Parallel ]]--
-- Model subclass, 
-- Composite of Models
-- Replaces nn.Parallel. Used for optimzation and evaluation.
------------------------------------------------------------------------
local Parallel, parent = torch.class("dp.Parallel", "dp.Container")
Parallel.isParallel = true

function Parallel:__init(config)
   config = config or {}
   config.typename = 'parallel'
   parent.__init(self, config)
end

function Parallel:setup(config)
   parent.setup(self, config)
   config.container = self
   for i, model in ipairs(self._models) do
      config.id = self:id():create('p'..i)
      model:setup(config)
   end
end

function Parallel:_forward(state)
   
   for idx,act in self.input.act:pairs() do
      local model = self._models[idx]
      local state = state:parallelClone()
      local state = dp.State{
         input=input, global=carry,
         carry=input_carrys[input_idx]
      }
      if carry.evaluate then
         output, carry = model:evaluate(input)
      else
         output, carry = model:forward(state)
      end
      
   end
   return carry
end

function Parallel:_backward(carry)
   local output = self.output
   for i=#self._models,1,-1 do
      local state = {output=output,global=carry,carry=carry}
      output, carry = self._models[i]:backward(state)
   end
   self.input = output
   return carry
end

function Parallel:flux(state)
   local output = self.output
   -- setup
   for i=1,#self._models-1 do
      self._models[i]:setSuccessor(self._models[i+1])
   end
   return self._model[1]:flux()
   self.input = output
   return carry
end

function Parallel:__tostring__()
   local tab = '  '
   local line = '\n'
   local next = ' -> '
   local str = 'dp.Parallel'
   str = str .. ' {' .. line .. tab .. '[input'
   for i=1,#self._models do
      str = str .. next .. '(' .. i .. ')'
   end
   str = str .. next .. 'output]'
   for i=1,#self._models do
      str = str .. line .. tab .. '(' .. i .. '): ' .. tostring(self._models[i]):gsub(line, line .. tab)
   end
   str = str .. line .. '}'
   return str
end

