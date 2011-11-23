--[[
   pirate_rhinos 1 of 3
   
   stages
   0) go to sys
   1) trigger pirate attack
   2) do pirate attack
   3) do escort
   4) escort compleat report to Wilson
   
   Author: MPink
]]--

include "scripts/numstring.lua"
include "scripts/nextjump.lua"
include "scripts/chatter.lua"

lang = naev.lang()
if lang == "es" then
   -- not translated atm
else -- default english
   bar_desc = "You see an Empire Commander. He is casually checking out the other patrons, probable searching for new talent."
   misn_title = "Empire Patrol"
   misn_reward = "%s credits"
   
   misn_desc = {}
   misn_desc[1] = "Go to the %s system."
   misn_desc[2] = "Check all the jumps for pirates"
   misn_desc[3] = "Report back"
   misn_desc["__save"] = true
   misn_desc_2 = "Save the %s from the pirates"
   misn_desc_3 = "Escort %s back to base"
   misn_desc_4 = "Report back"
   
   title = {}
   title[1] = "Spaceport Bar"
   title[2] = "Briefing"
   title[3] = "Distress Call"
   title[4] = "Mission Report"
   title[5] = "Mission Failed"
   
   text = {}
   text[1] = [[You approach the Empire Commander.
   
"Hi, you must be %s. I've heard about you. I'm Commander Wilson. Im looking for pilots to help protect our shipping lanes and you look like your ready for some action ?"]]
   text[2] = [["The empire has lost some of its rhinos to pirate attacks in the %s system. I would like you to go there and patrol the system for me. You would need to check the jumps for pirates and monitor the systems com traffic for any distress calls. We cant afford to keep on loosing rhinos at this pace. keep your eyes open and be ready for anything."]]
   text[3] = [["This is the %s calling all ships in range. We have pirates inbound and need assistance now. We are heading for the %s jump at best speed but wont make it without some help."]]
   text[4] = [[Commander Wilson is waiting for you in the hanger

"Hi %s. Glad to see you back in one pice. The last pilot that patrolled there come to a bad end. The %s informed me of your help and your sensor logs have provided vital intel into this new threat. We must resecure these trade lanes against these pirates. Im having missile jammers fitted to all the rhinos and have suspended the routes for ships without them. Its only a matter of time before they find a new security hole and change tactics again though."

Wilson's face suddenly changes to resemble someone who's just been struck on the head

"I have an idea but need to get some things in place. Meet me in the bar shortly if your up for some payback and ill tell you every thing"

It looks like Burt has a hard time thinking and you can only wonder what crazy plan he is hatching]]
   text[5] = [[Mission failure due to jumping before your escort]]
   
   comms = {}
   comms[1] =[[Thanks %s you save our skins]]
   comms[2] =[[Just another day at the office]]
   comms[3] =[[Why dont you guys have escorts ?]]
   comms[4] =[[There is only a limited supply of pilots capable of escorting over such a long range and we drew the short straw. Its good to see the Commander has found someone else to help out at last though.]]
   comms[5] =[[My patrol is about done hear so i will escort you the rest of the way]]
end


function create ()
   -- Plan the route
   jump_route = FindRoute( system.get("Volus"), system.get("Waterhole") )
   jump_route["__save"] = true
   jump_index = 2;
   base_planet = planet.get("Madeleine Station")
   
   -- Setup mission vars
   triger_dist = 5000--dist from eatery jump to do trigger
   rhino_armour=100 rhino_shields=100 rhino_stress=0-- store rhino values between jumps because im evil
   rhino_name = "Silver Express"
   adm_name = "Disabled Dave"-- dave is a bit of a spaco and cant even disable a rhino with 4 medusa launchers
   rhino_to_jump = 120--in seconds
   pirates_to_rhino = 45--in seconds
   adm_attacked=false
   rhino_has_jumped=false
   -- Hacks to replace with a good disabling AI
   -- (500-174)*5 = 1630 this is the very limit of the medusa but lockon time shall put it well inrange
   pirates_wep_range = 2000 -- Remove this when the AI learns about veriable range due to targets velocity
   pirates_disable_hack_range = 900 -- Remove this when the AI learns to disable
   
   -- Format all text events and make sure the tables saved else they will revert onload
   text[1] = text[1]:format( player.name())
   text[2] = text[2]:format( jump_route[jump_index]:name())
   text["__save"]=true
   misn_desc[1] = misn_desc[1]:format( jump_route[jump_index]:name())
   misn_desc["__save"]=true
   misn_desc_2 = misn_desc_2:format( rhino_name )
   misn_desc_3 = misn_desc_3:format( rhino_name )
   comms[1] = comms[1]:format(player.name())
   comms["__save"]=true

   -- Spaceport bar stuff
   misn.setNPC( "Commander", "empire/unique/soldner" )
   misn.setDesc( bar_desc )
end


function accept ()

   -- Intro text
   if not tk.yesno( title[1], text[1] ) then
      misn.finish()
   end
   -- Accept mission
   misn.accept()
   
   -- do main brief 
   tk.msg(title[2], text[2])
   -- mini briefing
   misn.osdCreate(title[2], {misn_desc[1]:format(jump_route[jump_index]:name())})
   
   -- target destination
   misn_marker = misn.markerAdd( jump_route[jump_index], "low" )
   
   misn_stage = 0
   reward = 80000
   misn.setTitle(misn_title)
   misn.setReward( string.format(misn_reward, numstring(reward)) )
   misn.setDesc( string.format("%s\n\n%s\n\n%s",misn_desc[1],misn_desc[2],misn_desc[3]) )
   misn.osdCreate(misn_title, misn_desc)

   
   -- start distance checking loop
   timing_loop()-- needs an onload trigger too

   -- Set hooks
   hook.jumpin("jumpin")
   hook.load("timing_loop")
   hook.land("land")
end


-- check for end of mission
function land ()
   if misn_stage==4 and planet.cur()==base_planet then
      tk.msg(title[4], string.format( text[4], player.name(), rhino_name))
      player.pay( reward )
      faction.modPlayerSingle("Dvaered", 2 )
      faction.modPlayerSingle("Pirate", -4)
      misn.finish(true)
   end
end


function jumpin ()
   -- delay jumpin hook to prevent early mission trigger when approaching jump
   hook.timer(500,"delayed_jumpin")
end
function delayed_jumpin ()
   if system.cur()==jump_route[2] then
      if misn_stage==0 then
         misn_stage=1
         misn.osdActive(2)
      end
   else
      if misn_stage<=1 then
         misn_stage=0
         misn.osdActive(1)
      end
   end
   
   if misn_stage==3 then
      if not rhino_has_jumped then
         tk.msg( title[5], text[5] )
         misn.finish(false)
      else
         -- setup rhino
         rhino_has_jumped=false
         rhino = pilot.add("Empire Rhino", "empire",  system.cur():jumpPos(jump_route[jump_index-1]), "Empire" )[1]
         prepear_rhino();
      end
  end
  
  rhino_has_jumped=false;
end

-- self calling timing loop (run only once)
-- checks for stage 2 (leaving enter gate)
function timing_loop ()

   -- check for mission stage trigger
   if misn_stage==1 then
      local pos = jump_route[jump_index]:jumpPos(jump_route[jump_index+1])-player.pilot():pos()
      if pos:dist()>triger_dist then
         misn_stage=2
         misn.setDesc(misn_desc_2)
         misn.osdCreate(misn_title, {misn_desc_2})
         misn.osdActive(1)
         
         tk.msg( title[3], string.format( text[3], rhino_name, jump_route[jump_index+1]:name()) )
         
         local jump_normal = jump_route[jump_index]:jumpPos(jump_route[jump_index-1]) - jump_route[jump_index]:jumpPos(jump_route[jump_index+1])
         jump_normal = jump_normal / jump_normal:dist()
         
         -- setup rhino
         rhino = pilot.add("Empire Rhino", "empire", vec2.new(0,0), "Empire" )[1]
         rhino:setHilight(true)
         rhino:setVisplayer()
         local rhino_ms = rhino:stats().speed_max
--         rhino:setDir((180/math.pi)*jump_normal:polar()[1])
         rhino:setPos( jump_route[jump_index]:jumpPos(jump_route[jump_index+1]) + (jump_normal*(rhino_ms*rhino_to_jump)) )
         rhino:setVel(jump_normal*(-rhino_ms) )
         hook.pilot(rhino,"board","rhino_dead")
         prepear_rhino();

         -- setup pirate
         adm = pilot.add("Pirate Admonisher", "pirate", vec2.new(0,0), "Pirate" )[1]
         adm:rename(adm_name)
         adm:rmOutfit("all")
         adm:addOutfit("Enygma Systems Spearhead Launcher")
         adm:addOutfit("Unicorp Medusa Launcher",4)
--         adm:addOutfit("Heavy Ion Cannon",2)
         adm:setHilight(true)
         adm:setVisplayer()
         local adm_ms = adm:stats().speed_max
--         adm:setDir((180/math.pi)*jump_normal:polar()[1])
         adm:setPos( rhino:pos() + (jump_normal*((adm_ms-rhino_ms)*pirates_to_rhino)) + (jump_normal*pirates_wep_range) )
         adm:setVel(jump_normal*(-adm_ms) )
         adm:control()
         adm:taskClear()
         adm:goto(jump_route[jump_index]:jumpPos(jump_route[jump_index+1]))
         hook.pilot(adm,"exploded","pirate_dead")

      end
   end
   
   -- hack to stop pirate firing until in range
   if not adm_attacked then
      if misn_stage==2 then
         if rhino:exists() and adm:exists() then
            if (rhino:pos()-adm:pos()):dist()<pirates_wep_range then
               adm_attacked=true
               adm:control(true)
               adm:taskClear()
               adm:attack(rhino)
               hook.pilot(adm,"idle","rhino_dead")
            end
         end
      end
   -- hack to disable rhino as dave cant do it on his own :(
   else
      if rhino:exists() and adm:exists() then
         if (rhino:pos()-adm:pos()):dist()<pirates_disable_hack_range then
--            rhino:disable()
            rhino_armour,rhino_shields,rhino_stress = rhino:health();
            rhino_stress=100
            rhino:setHealth(rhino_armour,rhino_shields,rhino_stress) 
         end
      end
   end
   
   hook.timer(1000,"timing_loop")
end

--------------------
--                --
--  PIRATE HOOKS  --
--                --
--------------------
-- update mission and clear board hook
function pirate_dead ()
   misn_stage=3
   misn.setDesc(misn_desc_3)
   misn.osdCreate(misn_title, {misn_desc_3})
   misn.osdActive(1)
   rhino:hookClear();
   hook.pilot(rhino,"exploded","rhino_dead")
   hook.pilot(rhino,"jump","rhino_jumped")
   hook.pilot(rhino,"idle","rhino_idle")
--   tk.msg(title[4], string.format( text[4], player.name(), rhino_name))
   local pp = player.pilot()
   hook.timer( 2000, "chatter", {pilot=rhino, text = comms[1]} )
   hook.timer( 5000, "chatter", {pilot=pp   , text = comms[2]} )
   hook.timer( 8000, "chatter", {pilot=pp   , text = comms[3]} )
   hook.timer(11000, "chatter", {pilot=rhino, text = comms[4]} )
   hook.timer(16000, "chatter", {pilot=pp   , text = comms[5]} )
end

-------------------
--               --
--  RHINO HOOKS  --
--               --
-------------------
-- fit the rhino, set its health and place the hooks
function prepear_rhino ()
   rhino:rename(rhino_name)
   rhino:rmOutfit("all")
   rhino:addOutfit("Turreted Gauss Gun",4)
   rhino:addOutfit("Shield Booster",2)
   rhino:addOutfit("Droid Repair Crew",1)
   rhino:addOutfit("Fuel Pod",2)
   rhino:addOutfit("Nanobond Plating",2)
   rhino:control()
   rhino:taskClear()
   rhino_idle()
   rhino:setHealth(rhino_armour,rhino_shields,rhino_stress)
   hook.pilot(rhino,"exploded","rhino_dead")
   hook.pilot(rhino,"idle","rhino_idle")
   hook.pilot(rhino,"jump","rhino_jumped")
end
-- do nav and marker updates
function rhino_jumped ()
   rhino_has_jumped = true
   jump_index = jump_index+1
   misn.markerMove( misn_marker,jump_route[jump_index])
   rhino_armour,rhino_shields,rhino_stress = rhino:health();
end
-- rhino dead or boarded ether way the mission is over
function rhino_dead ()
   -- reset pirate control
   if adm:exists() then
      adm:setHilight(false)
      adm:setVisplayer(false)
      adm:control(true)
      adm:taskClear()
      adm:control(false)
   end
   
   -- transfer rhino to pirates
   if rhino:exists() then
      rhino:setHilight(false)
      rhino:setVisplayer(false)
      rhino:changeAI("pirate")
      rhino:setFaction("Pirate")
      hook.timer(5000,"restart_rhino")-- hack needed to fix disable hack :(
   else
      -- ships dead so mission is over
      misn.finish(false)
   end
end
-- hack for restarting the rhino
function restart_rhino ()
   rhino_armour,rhino_shields,rhino_stress = rhino:health();
   rhino_stress=0;
   rhino:setHealth(rhino_armour,rhino_shields,rhino_stress)
   rhino:taskClear()
   rhino:control(false)
   misn.finish(false)
end
-- happens if it is shot off a jump point (not confirmed this as a fix yet though)
function rhino_idle ()
   if #jump_route==jump_index then
      rhino:land(base_planet)
      hook.pilot(thino,"land","rhino_landed")
   else
      rhino:hyperspace(jump_route[jump_index+1],true)
   end
end
-- hopefully this means we made it to our dest
function rhino_landed ()
   misn_stage=4
   misn.setDesc(misn_desc_4)
   misn.osdCreate(misn_title, {misn_desc_4})
   misn.osdActive(1)
end
