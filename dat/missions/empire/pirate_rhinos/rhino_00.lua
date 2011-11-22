--[[
   pirate_rhinos 1 of 3
   
   got to sys
   check jumps
   triger attack when near a jump
   save distreased ship or fail mission
   escort ship home
   
   stages
   0) go to sys
   1) trigger pirate attack
   2) do pirate attack
   3) do escort
   4) escort compleat report to bert
   
   Author: MPink
]]--

include "scripts/numstring.lua"
include "scripts/nextjump.lua"

lang = naev.lang()
if lang == "es" then
   -- not translated atm
else -- default english
   bar_desc = "You see an Empire Commander. He is casually checking out the other patrons, probable shearching for new talent."
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
   title[4] = "Rhino Saved"
   title[5] = "Mission Report"
   
   text = {}
   text[1] = [[You approach the Empire Commander.
   
"Hi, you must be %s. I've heard about you. I'm Commander Bert. Im looking for pilots to help protect our shipping lanes and you look like your ready for some action ?"]]
   text[2] = [["The empire has lost some of its rhinos to pirate attacks in the %s system. I would like you to go there and patrol the system for me. You would need to check the jumps for pirates and monitor the systems com traffic for any distress calls. We cant afford to keep on loosing rhinos at this pace. keep your eyes open and be ready for anything."]]
   text[3] = [["This is the %s calling all ships in range. We have pirates inbound and need assistance now. We are heading for the %s jump at best speed but wont make it without some help."]]
   -- replace with com chatter
   text[4] = [[Rhino:"Thanks %s you save our skins"
  
You:"Why dont you guys have escorts ?"

Rhino:"There is only a limited supply of pilots capable of escorting over such a long range and we drew the short straw. Its good to see Bert has found someone to help out at last though."

You:"My patrol is about done hear so i will escort you the rest of the way"]]
   text[5] = [["Hi %s. Glad to see you back in one pice. The last pilot that patrolled there come to a bad end. The %s informed me of your help and your sensor logs have provided vital intel into this new threat. We must resecure these trade lanes against these pirates. Im having missile jammers fitted to all the rhinos and have suspended the routes for ships without them. Its only a matter of time before they find a new security hole and change tactics again though."
   
"I have an idea but need to get some things in place. Meet me in the bar shortly if your up for some payback and ill tell you every thing"]]
end


function create ()
   -- Note: this mission does not make any system claims.
   -- Target destination
   triger_dist = 5000--dist from eatery jump to do trigger
   
   jump_route = FindRoute( system.get("Volus"), system.get("Waterhole") )
   jump_route["__save"] = true
   jump_index = 2;
   base_planet = planet.get("Madeleine Station")
   
   rhino_name = "Silver Express"
   adm_name = "Disabled Dave"-- dave is a bit of a spaco and cant even disable a rhino with 4 medusa launchers
   rhino_to_jump = 120--in seconds
   pirates_to_rhino = 45--in seconds
   pirates_wep_range = 2000 -- (500-174)*5 = 1630 this is the very limit of the medusa but lockon time shall put it well inrange
   pirates_disable_hack_range = 1000 -- Remove this when the AI learns to disable
   adm_attacked=false
   rhino_has_jumped=false

   -- Spaceport bar stuff
   misn.setNPC( "Commander", "empire/unique/soldner" )
   misn.setDesc( bar_desc )
end


function accept ()

   -- Intro text
   if not tk.yesno( title[1], string.format( text[1], player.name()) ) then
      misn.finish()
   end
   -- Accept mission
   misn.accept()
   
   -- do main brief 
   tk.msg(title[2], string.format( text[2], jump_route[jump_index]:name()))
   -- mini briefing
   misn.osdCreate(title[2], {misn_desc[1]:format(jump_route[jump_index]:name())})
   
   -- target destination
   misn_marker = misn.markerAdd( jump_route[jump_index], "low" )

   -- Mission details
   misn_desc[1] = misn_desc[1]:format( jump_route[jump_index]:name())
   misn_desc_2 = misn_desc_2:format( rhino_name )
   misn_desc_3 = misn_desc_3:format( rhino_name )
   
   misn_stage = 0
   reward = 80000
   misn.setTitle(misn_title)
   misn.setReward( string.format(misn_reward, numstring(reward)) )
   misn.setDesc( string.format("%s\n\n%s\n\n%s",misn_desc[1],misn_desc[2],misn_desc[3]) )
   misn.osdCreate(misn_title, misn_desc)

   
   -- start distence checking loop
   timing_loop()-- needs an onload trigger too

   -- Set hooks
   hook.jumpin("jumpin")
   hook.load("timing_loop")
   hook.land("land")
end


-- check for end of mission
function land ()
   if misn_stage==4 then
      tk.msg(title[5], string.format( text[5], player.name(), rhino_name))
      player.pay( reward )
      faction.modPlayerSingle("Dvaered", 2 )
      faction.modPlayerSingle("PIRATE", -4)
      misn.finish(true)
   end
end


function jumpin ()
   -- delay jumpin hook to prevent early mission trigger when approaching jump
   hook.timer(500,"delayed_jumpin")
end
function delayed_jumpin ()
   print(string.format("delayed_jumpin stage=%d",misn_stage))
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
         print("misn end no rhino jump")
         -- display a you fucked up msg
         misn.finish(false)
      else
         -- setup rhino
         print("rhino setup")
         rhino_has_jumped=false
         rhino = pilot.add("Empire Rhino", "empire",  system.cur():jumpPos(jump_route[jump_index-1]), "Empire" )[1]
         rhino:setHilight(true)
         rhino:setVisplayer()
         rhino:rename(rhino_name)
         rhino:control()
         rhino:taskClear()
         rhino_idle()
         hook.pilot(rhino,"exploded","lost_ship")
         hook.pilot(rhino,"jump","rhino_jumped")
         hook.pilot(rhino,"idle","rhino_idle")
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
         rhino:rename(rhino_name)
         rhino:setPos( jump_route[jump_index]:jumpPos(jump_route[jump_index+1]) + (jump_normal*(rhino_ms*rhino_to_jump)) )
         rhino:setVel(jump_normal*(-rhino_ms) )
         rhino:control()
         rhino:taskClear()
         rhino_idle()
         hook.pilot(rhino,"exploded","lost_ship")
         hook.pilot(rhino,"board","lost_ship")
         hook.pilot(rhino,"idle","rhino_idle")

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
               hook.pilot(adm,"idle","lost_ship")
            end
         end
      end
   else
      if rhino:exists() and adm:exists() then
         if (rhino:pos()-adm:pos()):dist()<pirates_disable_hack_range then
            rhino:disable()
         end
      end
   end
   
   hook.timer(1000,"timing_loop")
end

function lost_ship ()
   --reset pirate control
   if adm:exists() then
      adm:setHilight(false)
      adm:setVisplayer(false)
      adm:control(true)
      adm:taskClear()
      adm:control(false)
   end
   
   --transfer rhino to pirates
   if rhino:exists() then
      rhino:setHilight(false)
      rhino:setVisplayer(false)
      rhino:changeAI("pirate")
      rhino:setFaction("Pirate")
      hook.timer(5000,"restart_rhino")-- hack needed due to disable hack :(
      print("lost_ship rhino restart timer started")
   else
      --ships dead so mission is over
      misn.finish(false)
   end
end

function restart_rhino ()
   print("rhino_restart_hack")
   rhino:setHealth(100,1,0)
   rhino:taskClear()
   rhino:control(false)
   misn.finish(false)
end

function pirate_dead ()
   misn_stage=3
   misn.setDesc(misn_desc_3)
   misn.osdCreate(misn_title, {misn_desc_3})
   misn.osdActive(1)
   rhino:hookClear();
   hook.pilot(rhino,"exploded","lost_ship")
   hook.pilot(rhino,"jump","rhino_jumped")
   hook.pilot(rhino,"idle","rhino_idle")
   tk.msg(title[4], string.format( text[4], player.name(), rhino_name))
end

function rhino_jumped ()
   print("rhino_jumped")
   rhino_has_jumped = true
   jump_index = jump_index+1
   misn.markerMove( misn_marker,jump_route[jump_index])
end

-- happens if it is shot off a jump point
function rhino_idle ()
   if #jump_route==jump_index then
      rhino:land(base_planet)
      hook.pilot(thino,"land","rhino_landed")
   else
      rhino:hyperspace(jump_route[jump_index+1],true)
   end
end

function rhino_landed ()
   misn_stage=4
   misn.setDesc(misn_desc_4)
   misn.osdCreate(misn_title, {misn_desc_4})
   misn.osdActive(1)
end