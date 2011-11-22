-- Choose the next system to jump to on the route from system nowsys to system finalsys.
function getNextSystem(nowsys, finalsys)
    if nowsys == finalsys then
        return nowsys
    else
        local neighs = nowsys:adjacentSystems()
        local nearest = -1
        local mynextsys = finalsys
        for _, j in pairs(neighs) do
            if nearest == -1 or j:jumpDist(finalsys) < nearest then
                nearest = j:jumpDist(finalsys)
                mynextsys = j
            end
        end
        return mynextsys
    end
end

-- return a table of systems for a route from start to end
function FindRoute ( start_sys_, end_sys_ )
   local checked_sys_ary = {start_sys_}
   local routes = {{start_sys_}} -- a table of tables
   
   while #routes>0 do
      local current_rt = table.remove(routes,1)
      local current_sys = current_rt[#current_rt]
      local rt_string = ""
      for k,v in pairs(current_rt) do rt_string=string.format("%s %s",rt_string,v:name()) end

      -- loop through adjacent systems
      for _,sys in pairs(current_sys:adjacentSystems()) do
         -- check system has not already been added to a route
         if not Contains(checked_sys_ary,sys) then
            local next_route = Copy(current_rt)
            table.insert(next_route,sys)
            table.insert(checked_sys_ary,sys)
            table.insert(routes,next_route)
            -- return found route
            if sys==end_sys_ then return next_route end
         end
      end
   end
   
   return {}
end

function Contains (table_,value_)
   for _,v in pairs(table_) do
      if v==value_ then return true end
   end
   return false
end
function Copy (table_)
   local result = {}
   for _,v in pairs(table_) do table.insert(result,v) end
   return result
end