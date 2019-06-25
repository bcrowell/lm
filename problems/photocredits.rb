#!/usr/bin/ruby

# Most of the entries are cut and pasted from other books.

require 'json'

$credits = {}

def photo_credit(file,description,credit)
  $credits[file] = [description,credit]
end

photo_credit("hw-iss-apparent-gravity","ISS","NASA/Crew of STS-132, public domain") # https://commons.wikimedia.org/wiki/File:International_Space_Station_after_undocking_of_STS-132.jpg
photo_credit("hw-moment-of-inertia-lab","Terrier","Redrawn from a painting by Frederick August Wenderoth, 1875") # http://en.wikipedia.org/wiki/File:Frederick_August_Wenderoth_1875,_Little_Terrier.jpg
photo_credit("hw-rappel-from-fridge","Rappelling","Redrawn from a photo by Jarek Tuszymski, CC-BY-SA") # https://commons.wikimedia.org/wiki/File:Elizabeth_Furnace_-_Repeling.JPG
photo_credit("hw-cd-constant-linear-velocity","CD","Wikimedia Commons user Zaphraud, CC-BY-SA") # https://en.wikipedia.org/wiki/File:CDRomPits.jpg
photo_credit("hw-firehose","Firehose","Public-domain work of the U.S. Navy") # https://commons.wikimedia.org/wiki/File:DN-SN-87-07338_USS_Claude_V._Ricketts_sprays_to_USS_Belknap_19751122.jpeg
photo_credit("pulley-table-two-blocks-sloth","Sloth","Redrawn from a photo by Christian Mehlfuhrer, CC-BY-SA") # https://en.wikipedia.org/wiki/File:MC_Drei-Finger-Faultier.jpg
photo_credit("hw-cliff-pond","Diver","Redrawn from a photo provided by the Deutsches Bundesarchiv cooperation project, CC-BY-SA") # https://commons.wikimedia.org/wiki/File:Bundesarchiv_Bild_183-C0821-0013-001,_Interpress-Foto_66%22_in_Moskau%22.jpg
photo_credit("hw-bug-turntable","Ladybug","Redrawn from a photo by Wikimedia Commons user Gilles San Martin, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:Coccinella_magnifica01.jpg
photo_credit("bug-pe","Ladybug","Redrawn from a photo by Wikimedia Commons user Gilles San Martin, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:Coccinella_magnifica01.jpg
photo_credit("bug-pe","Hand","Biswarup Ganguly, CC-BY-SA") # https://commons.wikimedia.org/wiki/File:Left_Hand_-_Kolkata_2011-04-20_2351.JPG
photo_credit("munchausen","Baron von Munchausen","Theodor Hosemann, public domain")
photo_credit("hw-skee-ball","Skee ball","Photo by Wikipedia user Joyous!, CC-BY-SA") # https://commons.wikimedia.org/wiki/File:Skee_Ball.JPG
photo_credit("hw-posnegwork-bull","Bull","Photo by Wikimedia Commons user Bart Hiddink, CC-BY") # https://upload.wikimedia.org/wikipedia/commons/f/fd/Angry_Bull_in_Pasture.jpg
photo_credit("hw-car-in-mud","Man pushing car","Line art by the author, based on a photo by Wikimedia Commons user Auregann, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:Voiture_embourb%C3%A9e.JPG
photo_credit("hw-lowering-climber","Climber being lowered","Art by the author, based on photos by Wikimedia Commons users  Alexander Stohr and Absinthologue, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:Grottes_du_Loup_-_Main_sector-Portail_Alpinisme_et_escalade_01.jpg http://commons.wikimedia.org/wiki/File:Abseilen_einer_Person.jpg
photo_credit("caryatid","Caryatid","Art by the author, based on a photo by Wikimedia Commons user Thermos, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:Porch_of_Maidens.jpg
photo_credit("passing-in-race","Runners","Line art by the author, based on a photo by Pierre-Yves Beaudouin, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:2014_D%C3%A9caNation_-_800_m_19c.jpg
photo_credit("eg-push-broom","Man pushing broom","Line art by the author, based on a public-domain photo by a U.S.~National Park Service employee, CC-BY licensed") # http://commons.wikimedia.org/wiki/File:Grain_off-loading_procedure,_workmen_using_hand_shovels_and_push_brooms_to_load_marine_leg_during_final_stages_of_off_loading_-_Buffalo_Grain_Elevators,_Buffalo,_Erie_County,_NY_HAER_NY,15-BUF,27-37.tif
photo_credit("greyhound","Greyhound","Line art by the author, based on a photo by Alex Lapuerta, CC-BY licensed") # http://commons.wikimedia.org/wiki/File:Greyhound_racing_turn.jpg
photo_credit("tetherball","Tetherball","Line art by the author, based on a photo by The Chewonki Foundation (Flickr), CC-BY-SA 2.0 licensed")
photo_credit("hw-langley-catapult","Langley catapult launch","Public domain (1903)") # http://en.wikipedia.org/wiki/File:SpX_CRS-2_launch_-_further_-_cropped.jpg
photo_credit("spacex-launch","space launch","NASA, public domain") # http://en.wikipedia.org/wiki/File:SpX_CRS-2_launch_-_further_-_cropped.jpg
photo_credit("playing-card","playing card","German wiktionary.org user Ranostaj, CC-BY-SA license") # http://commons.wikimedia.org/wiki/File:Bild-VierOber.jpg
photo_credit("eg-top-and-tuning-fork","top","Randen Pederson, CC-BY") # http://commons.wikimedia.org/wiki/File:Topspun.jpg
photo_credit("eg-top-and-tuning-fork","tuning fork","Wikimedia Commons, CC-BY-SA, user Wollschaf") # http://commons.wikimedia.org/wiki/File:Stimmgabel.jpg
photo_credit("toutatis","Toutatis","Chang'e-2") # 
photo_credit("shell-theorem","Galaxy and star","Hubble Space Telescope. Hubble material is copyright-free and may be freely used as in the public domain without fee, on the condition that NASA and ESA
is credited as the source of the material. The material was created for NASA by STScI under Contract NAS5-26555 and for ESA by the Hubble European Space Agency Information Centre")
photo_credit("shell-theorem","Saturn","Public domain, NASA") # http://en.wikipedia.org/wiki/File:Saturn-cassini-March-27-2004.jpg
photo_credit("shell-theorem","Human figures","Line art by B.~Crowell, CC-BY-SA licensed. Based on a photo by Richard Peter/Deutsche Fotothek, CC-BY-SA licensed.") # http://en.wikipedia.org/wiki/File:Fotothek_df_ps_0000628_Sport_%5E_Felsen.jpg
photo_credit("hw-wall-of-death","Runner","Line art by B.~Crowell, CC-BY-SA licensed. Based on a photo by Wikimedia Commons user Fengalon, public domain") # http://commons.wikimedia.org/wiki/File:Running.gif
photo_credit("hw-layback","Rock climber","Line art by B.~Crowell, CC-BY-SA licensed. Based on a photo by Richard Peter/Deutsche Fotothek, CC-BY-SA licensed.") # http://en.wikipedia.org/wiki/File:Fotothek_df_ps_0000628_Sport_%5E_Felsen.jpg
photo_credit("fall-factor","Rock climber","Line art by B.~Crowell, CC-BY-SA licensed. Based on a photo by Jason McConnell-Leech, CC-BY-SA licensed.") # http://en.wikipedia.org/wiki/File:Lead_climb_indoor001.jpg
photo_credit("hw-cowcrush","Farmer and cow","Michael Han, CC-BY-SA license")
photo_credit("hw-golf-ball-packing","Stacked oranges","Wikimedia Commons user J.J.~Harrison, CC-BY-SA license") # http://commons.wikimedia.org/wiki/File:HCP_Oranges.jpg
photo_credit("hw-stride","Dinosaur","Redrawn from art by Wikimedia Commons user Dinoguy2, CC-BY-SA license") # http://en.wikipedia.org/wiki/File:Spinosaurus_BW2.png
photo_credit("hw-stride","Sprinter","Drawn from a photo provided by the German Federal Archives under a CC-BY-SA license") # http://en.wikipedia.org/wiki/File:Bundesarchiv_Bild_183-1987-0822-034,_Sabine_Busch,_Cornelia_Ulrich.jpg
photo_credit("muscle-contraction","Male gymnast","Wikipedia user Gonzo-wiki, public domain") # http://en.wikipedia.org/wiki/File:Example2ofironcross.jpg
photo_credit("muscle-contraction","Woman doing pull-ups","Sergio Savarese, CC-BY") # http://commons.wikimedia.org/wiki/File:Amanda_Fran%C3%A7ozo_At_The_Runner_Sports-7.jpg
photo_credit("jelly-beans","Jar of jellybeans","Flickr user cbgrfx123, CC-BY-SA licensed") # http://www.flickr.com/photos/72005145@N00/5600978712/
photo_credit("eg-fifi","Dog","From a photo by Wikimedia Commons user Ron Armstrong, CC-BY licensed") # http://commons.wikimedia.org/wiki/File:Chinese_Crested_hairless_agility.jpg
photo_credit("hw-airplaneforces","Biplane","Open Clip Art Library, public domain") # http://commons.wikimedia.org/wiki/File:Qsjapaneseicon-getinandgo.png
photo_credit("amphicoelias","Amphicoelias","Wikimedia commons users Dinoguy2, Niczar, ArthurWeasley, Steveoc 86, Dropzink, and Piotr Jaworski, CC-BY-SA licensed") # http://commons.wikimedia.org/wiki/File:Largestdinosaursbysuborder_scale.svg
photo_credit("airbag","Air bag","DaimlerChrysler AG, CC-BY-SA licensed.") #http://commons.wikimedia.org/wiki/File:Airbag1.jpg
photo_credit("hw-estimate-flea-accel","Flea jumping","Burrows and Sutton, ``Biomechanics of jumping in the flea,'' J. Exp. Biology 214 (2011) 836. Used under the U.S.~fair use exception to copyright")
photo_credit("partridge-normal-and-friction","Partridge","Redrawn from K.P.~Dial, ``Wing-Assisted Incline Running and the Evolution of Flight,'' Science 299 (2003) 402")
photo_credit("standard-kilogram","Standard kilogram","Bo Bengtsen, GFDL licensed. Further retouching by Wikipedia user Greg L and by B.~Crowell") #http://en.wikipedia.org/wiki/File:Denmark%E2%80%99s_K48_Kilogram.jpg
photo_credit("climate-orbiter","Mars Climate Orbiter","NASA/JPL/CIT")
photo_credit("bee-flying","Bee","Wikipedia user Fir0002, CC-BY-SA licensed")
photo_credit("hw-e-coli","E. Coli bacteria","Eric Erbe, digital colorization by Christopher Pooley, both of USDA, ARS, EMU. A public-domain product of the Agricultural Research Service.")
photo_credit("seti-volume","Galaxy","ESO, CC-BY license") # http://en.wikipedia.org/wiki/File:NGC_4565.jpg
photo_credit("trapeze","Trapeze","Calvert Litho. Co., Detroit, ca. 1890")
photo_credit("gymnastics-wheel","Gymnastics wheel","Copyright Hans Genten, Aachen, Germany. ``The copyright holder of this file allows anyone to use it for any purpose, provided that this remark is referenced or copied.''")
photo_credit("high-jump","High jumper","Dunia Young")
photo_credit("rocket-sled","Rocket sled","U.S. Air Force, public domain work of the U.S. Government")
photo_credit("aristotle","Aristotle","Francesco Hayez, 1811")
photo_credit("shanghai-and-anaheim","Shanghai","Agnieszka Bojczuk, CC-BY-SA") #http://en.wikipedia.org/wiki/Image:Shanghai_-_Nanjing_Road.jpeg
photo_credit("shanghai-and-anaheim","Angel Stadium","U.S. Marine Corps, Staff Sgt. Chad McMeen, public domain work of the U.S. Government") #http://en.wikipedia.org/wiki/Image:Angel_Stadium.jpg
photo_credit("jets-in-formation-over-ny","Jets over New York","U.S. Air Force, Tech. Sgt. Sean Mateo White, public domain work of the U.S. Government") #http://en.wikipedia.org/wiki/Image:F-16_Fighting_Falcons_above_New_York_City%282%29.jpg
photo_credit("tuna","Tuna's migration","Modified from a figure in Block et al")
photo_credit("galileo-trial","Galileo's trial","Cristiano Banti (1857)")
photo_credit("global-gravity-map","Gravity map","US Navy, European Space Agency, D. Sandwell, and W. Smith")
photo_credit("hw-astronaut-jumping","Astronaut jumping","NASA")
photo_credit("newton","Newton","Godfrey Kneller, 1702")
photo_credit("shuttle-launch","Space shuttle launch","NASA")
photo_credit("swimming","Swimmer","Karen Blaha, CC-BY-SA licensed") #http://en.wikipedia.org/wiki/File:Phelps_400m_IM_Missouri_GP_2008.jpg
photo_credit("locomotive","Locomotive","Locomotive Cyclopedia of American Practice, 1922, public domain")
photo_credit("fluid-patterns","Wind tunnel","Jeff Caplan/NASA Langley, public domain") #http://commons.wikimedia.org/wiki/Image:Wind_tunnel_x-43.jpg
photo_credit("fluid-patterns","Crop duster","NASA Langley Research Center, public domain") #http://commons.wikimedia.org/wiki/Image:Airplane_vortex_edit.jpg
photo_credit("fluid-patterns","Series of vortices","Wikimedia Commons user Onera, CC-BY license") #http://commons.wikimedia.org/wiki/Image:FluidPhysics-Wake.jpg
photo_credit("fluid-patterns","Turbulence","C. Fukushima and J. Westerweel, Technical University of Delft, The Netherlands, CC-BY license") #http://commons.wikimedia.org/wiki/Image:Jet.jpg
photo_credit("fluid-dimples","Golf ball","Wikimedia Commons user Paolo Neo, CC-BY-SA license") #http://commons.wikimedia.org/wiki/Image:Golf-ball.jpg
photo_credit("fluid-dimples","Shark","Wikimedia Commons user Pterantula, CC-BY-SA license") #http://upload.wikimedia.org/wikipedia/commons/1/12/Whiteshark-TGoss1.jpg
photo_credit("hummer-vs-prius","Hummer","Wikimedia commons user Bull-Doser, public domain") # http://commons.wikimedia.org/wiki/Image:Hummer_H-3.JPG
photo_credit("hummer-vs-prius","Prius","Wikimedia commons user IFCAR, public domain") # http://commons.wikimedia.org/wiki/Image:2005-Toyota-Prius.jpg
photo_credit("golden-gate-bridge","Golden Gate Bridge","Wikipedia user Dschwen, CC-BY-SA licensed")
photo_credit("hw-oldlady","Football player and old lady","Hazel Abaya")
photo_credit("ringtoss","Ring toss","Clarence White, 1899")
photo_credit("mondavi","Aerial photo of Mondavi vineyards","NASA")
photo_credit("muybridge","Galloping horse","Eadweard Muybridge, 1878")
photo_credit("sled","Sled","Modified from Millikan and Gale, 1920")
photo_credit("hanging-boys","Hanging boy","Millikan and Gale, 1927")
photo_credit("hurricane-track","Hurricane track","Public domain, NASA and Wikipedia user Nilfanion") # http://en.wikipedia.org/wiki/Image:Irene_2005_track.png
photo_credit("motorcyclist","Motorcyclist","Wikipedia user Fir0002, CC-BY-SA licensed")
photo_credit("sparks-fly-on-tangent","Grinding wheel","Wikimedia commons user Bukk, public domain") # http://commons.wikimedia.org/wiki/File:Sparks_from_grinder.jpg
photo_credit("halteres","Crane fly","Wikipedia user Pinzo, public domain") #http://en.wikipedia.org/wiki/Image:Crane_fly_halteres.jpg
photo_credit("space-colony","Space colony","NASA")
photo_credit("tycho-brahe","Tycho Brahe","public domain")
photo_credit("saturn","Saturn","Voyager 2 team, NASA")
photo_credit("pluto","Pluto and Charon","Hubble Space Telescope, STSCi")
photo_credit("cavendish-simplified","Simplified Cavendish experiment","Wikimedia commons user Chris Burks, public domain.")
photo_credit("wmap","WMAP","NASA")
photo_credit("hw-uranus","Uranus","Voyager 2 team, NASA")
photo_credit("hw-uranus","Earth","Apollo 11, NASA")
photo_credit("new-horizons","New Horizons spacecraft image","Wikipedia user NFRANGA, CC-BY-SA") #http://en.wikipedia.org/wiki/File:New_Horizons_flyby_of_Pluto_-_horizons2015.png
photo_credit("new-horizons","New Horizons trajectory","Wikimedia commons user Martinw89, CC-BY-SA") #http://upload.wikimedia.org/wikipedia/commons/4/44/New_horizon_jupiter_flyby.svg
photo_credit("jupiter-comet","Jupiter","Images from the Hubble Space Telescope, NASA, not copyrighted")
photo_credit("hoover-dam","Hoover Dam","U.S. Department of the Interior, Bureau of Reclamation, Lower Colorado Region, not copyrighted")
photo_credit("hydraulic-ram","Hydraulic ram","Millikan and Gale, 1920")
photo_credit("energy-collage","Bonfire, grapes","CC-BY-SA licensed, by Wikipedia user Fir0002")
photo_credit("pool-skater","Skater in pool","Courtesy of J.D. Rogge")
photo_credit("plutonium-glowing","Plutonium pellet","U.S. Department of Energy, public domain.")
photo_credit("skater-rolls-off-pipe","Skateboarder on top of pipe","Oula Lehtinen, Wikimedia Commons, CC-BY-SA")
photo_credit("slingshot-sun-frame","Jupiter","Uncopyrighted image from the Voyager probe. Line art by the author")
photo_credit("baseball-pitch","Baseball pitch","Wikipedia user Rick Dikeman, CC-BY-SA") #http://en.wikipedia.org/wiki/Image:Baseball_pitching_motion_2004.jpg
photo_credit("breaking-trail","Breaking Trail","Art by Walter E. Bohl. Image courtesy of the University of Michigan Museum of Art/School of Information and Library Studies")
photo_credit("ion-drive","Deep Space 1 engine","NASA")
photo_credit("halley-nucleus","Nucleus of Halley's comet","NASA, not copyrighted")
photo_credit("chadwick","Chadwick's apparatus","Redrawn from the public-domain figure in Chadwick's original paper")
photo_credit("wrench","Wrench","PSSC Physics")
photo_credit("tornado","Tornado","NOAA Photo Library, NOAA Central Library; OAR/ERL/National Severe Storms Laboratory (NSSL); public-domain product of the U.S. government")
photo_credit("longjump","Longjump","Thomas Eakins, public domain")
photo_credit("diver","Diver","PSSC Physics")
photo_credit("conical-pendulum","Pendulum","PSSC Physics")
photo_credit("cow-tipping","Cow","Drawn by the author, from a CC-BY-SA-licensed photo on commons.wikimedia.org by user B.navez.")
photo_credit("windmills","Old-fashioned windmill","Photo by the author")
photo_credit("windmills","Modern windmill farm, Tehachapi, CA","U.S. Department of Energy, not copyrighted")
photo_credit("swan-lake","Ballerina","Alexander Kenney, CC-BY license") # http://commons.wikimedia.org/wiki/File:Nadja_Sellrup_in_Swan_Lake_2008.jpg
photo_credit("hw-whitedwarf","White dwarf","Image of NGC 2440 from the Hubble Space Telescope, H. Bond and R. Ciardullo")
photo_credit("otters","Otters","Dmitry Azovtsev, Creative Commons Attribution License, wikipedia.org")
photo_credit("hot-air-balloon","Hot air balloon","Randy Oostdyk, CC-BY-SA licensed") #http://commons.wikimedia.org/wiki/File:Ballon2.jpg
photo_credit("space-suit","Space suit","Jawed Karim, CC-BY-SA license") #http://commons.wikimedia.org/wiki/File:Apollo_15_Space_Suit_David_Scott.jpg
photo_credit("magdeburg","Magdeburg spheres","Millikan and Gale, Elements of Physics, 1927, reproduced from the cover of Magdeburg's book")
photo_credit("bass","Electric bass","Brynjar Vik, CC-BY license") #http://commons.wikimedia.org/wiki/Image:Gig_bass.jpg
photo_credit("jovian-moons","Jupiter","Uncopyrighted image from the Voyager probe. Line art by the author")
photo_credit("tacoma-collage","Tacoma Narrows Bridge","Public domain, from Stillman Fires Collection: Tacoma Fire Dept, www.archive.org")
photo_credit("nimitz-freeway","Nimitz Freeway","Unknown photographer, courtesy of the UC Berkeley Earth Sciences and Map Library")
photo_credit("tympanogram","Tympanometry","Perception The Final Frontier, A PLoS Biology Vol. 3, No. 4, e137; modified by Wikipedia user Inductiveload and by B. Crowell; CC-BY license")
photo_credit("gretchen-nmr","Two-dimensional MRI","Image of the author's wife")
photo_credit("three-dimensional-nmr","Three-dimensional brain","R. Malladi, LBNL")
photo_credit("hw-spider-oscillations","Spider oscillations","Emile, Le Floch, and Vollrath, \\emph{Nature} 440 (2006) 621")
photo_credit("hokusai","Painting of waves","Katsushika Hokusai (1760-1849), public domain")
photo_credit("coil-spring-superposition","Superposition of pulses","Photo from PSSC Physics")
photo_credit("ribbon-on-spring","Marker on spring as pulse passes by","PSSC Physics")
photo_credit("surfing-hand-drag","Surfing (hand drag)","Stan Shebs, CC-BY-SA licensed (Wikimedia Commons)")
photo_credit("ultrasound","Fetus","Image of the author's daughter")
photo_credit("breaking-wave","Breaking wave","Ole Kils, olekils at web.de, CC-BY-SA licensed (Wikipedia)")
photo_credit("circular-and-linear-wavelengths","Wavelengths of circular and linear waves","PSSC Physics")
photo_credit("wavelength-change","Changing wavelength","PSSC Physics")
photo_credit("doppler","Doppler effect for water waves","PSSC Physics")
photo_credit("doppler-radar","Doppler radar","Public domain image by NOAA, an agency of the U.S. federal government")
photo_credit("m51","M51 galaxy","public domain Hubble Space Telescope image, courtesy of NASA, ESA, S. Beckwith (STScI), and The Hubble Heritage Team (STScI/AURA)")
photo_credit("mount-wilson","Mount Wilson","Andrew Dunn, cc-by-sa licensed")
photo_credit("shock-wave","X15","NASA, public domain")
photo_credit("sonic-boom","Jet breaking the sound barrier","Public domain product of the U.S. government, U.S. Navy photo by Ensign John Gay")
photo_credit("human-cross-section","Human cross-section","Courtesy of the Visible Human Project, National Library of Medicine, US NIH")
photo_credit("fish-reflection","Reflection of fish","Jan Derk, Wikipedia user janderk, public domain")
photo_credit("circular-reflection","Reflection of circular waves","PSSC Physics")
photo_credit("pulse-reflected-from-fixed-end","Reflection of pulses","PSSC Physics")
photo_credit("coil-spring-reflections","Reflection of pulses","Photo from PSSC Physics")
photo_credit("guitar-and-model","Photo of guitar","Wikimedia Commons, dedicated to the public domain by user Tsca")
photo_credit("standing-waves-on-floor","Standing waves","PSSC Physics")
photo_credit("traffic","Traffic","Wikipedia user Diliff, CC-BY licensed") #http://commons.wikimedia.org/wiki/Image:Hollywood_boulevard_from_kodak_theatre.jpg
photo_credit("pan-pipes","Pan pipes","Wikipedia user Andrew Dunn, CC-BY-SA licensed") # http://en.wikipedia.org/wiki/Image:ChileanPanpipes-cutout.jpg
photo_credit("flute","Flute","Wikipedia user Grendelkhan, CC-BY-SA licensed")
photo_credit("qbert","Crab","From a photo by Hans Hillewaert, CC-BY-SA") # https://commons.wikimedia.org/wiki/File:Liocarcinus_vernalis.jpg
photo_credit("galaxies-signaling","Galaxies","Ville Koistinen, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:Hubble_sequence_photo.png
photo_credit("salamander","Salamander","Redrawn from an 18th century illustration by J.D.~Meyer") # https://commons.wikimedia.org/wiki/File:Meyer_Zeit-Vertreib_1_Tafel_054.jpg
photo_credit("salamander","Hand","Redrawn from a photo by Wikimedia Commons user Evan-Amos, CC-BY-SA") # https://commons.wikimedia.org/wiki/File:Human-Hands-Front-Back.jpg
photo_credit("machine-gun-ftl","Machine gunner's body","Redrawn from a public-domain photo by Cpl.~Sheila Brooks") # http://commons.wikimedia.org/wiki/File:V-22_M240_machine_gun.jpg
photo_credit("machine-gun-ftl","Machine gunner's head","Redrawn from a sketch by Wenceslas Hollar, 17th century") # http://commons.wikimedia.org/wiki/File:Wenceslas_Hollar_-_Woman%27s_head_seen_from_behind.jpg
photo_credit("c-s-wu-with-beamline","C.S.~Wu","Smithsonian Institution, believed to be public domain") # http://en.wikipedia.org/wiki/File:Chien-shiung_Wu_%281912-1997%29.jpg
photo_credit("swan-lake-symmetry","Swan Lake","Peter Gerstbach, GFDL 1.2") # 
photo_credit("fifty-foot-woman","Fifty-foot woman","Public domain due to nonrenewal of copyright") # http://commons.wikimedia.org/wiki/File:Attackofthe50ftwoman.jpg
photo_credit("zombies","Zombies","Public domain due to an error by the distributor in failing to place a copyright notice on the film") # http://commons.wikimedia.org/wiki/File:Night_of_the_Living_Dead_affiche.jpg
photo_credit("ladybug","Ladybug","Redrawn from a photo by Wikimedia Commons user Gilles San Martin, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:Coccinella_magnifica01.jpg
photo_credit("mri","MRI","Wikimedia Commons user Tomas Vendis, GFDL license") # http://commons.wikimedia.org/wiki/File:3TMRI.jpg
photo_credit("hw-lpcurrent","LP record","Felipe Micaroni Lalli, CC-BY-SA") # http://commons.wikimedia.org/wiki/File:Vynil_vinil_92837841.png
photo_credit("lion","The Sleeping Gypsy","H.~Rousseau, 1897") #http://en.wikipedia.org/wiki/File:A_Swarm_of_Ancient_Stars_-_GPN-2000-000930.jpg
photo_credit("globular-cluster","Globular cluster","Hubble Space Telescope. Hubble material is copyright-free and may be freely used as in the public domain without fee, on the condition that NASA and ESA is credited as the source of the material. The material was created for NASA by STScI under Contract NAS5-26555 and for ESA by the Hubble European Space Agency Information Centre") #http://en.wikipedia.org/wiki/File:A_Swarm_of_Ancient_Stars_-_GPN-2000-000930.jpg
photo_credit("balloon-metaphor","Galaxies","Hubble Space Telescope. Hubble material is copyright-free and may be freely used as in the public domain without fee, on the condition that NASA and ESA is credited as the source of the material. The material was created for NASA by STScI under Contract NAS5-26555 and for ESA by the Hubble European Space Agency Information Centre")
photo_credit("inertial-frame","Earth","NASA, Apollo 17. Public domain") #http://en.wikipedia.org/wiki/File:The_Earth_seen_from_Apollo_17.jpg
photo_credit("inertial-frame","Orion","Wikipedia user Mouser, GFDL") #http://en.wikipedia.org/wiki/File:Orion_3008_huge.jpg
photo_credit("inertial-frame","M100","European Southern Observatory, CC-BY-SA") #http://en.wikipedia.org/wiki/File:M100.jpg
photo_credit("inertial-frame","Superlcuster","Wikipedia user Azcolvin429, CC-BY-SA") #http://en.wikipedia.org/wiki/File:Universe_Reference_Map_%28Location%29_001.jpeg
photo_credit("artificial-horizon","Artificial horizon","NASA, public domain") #http://en.wikipedia.org/wiki/File:VMS_Artificial_Horizon.jpg
photo_credit("jumping-spider","Jumping spider","Photo: Wikipedia user Opoterser, CC-BY-SA. Line art: redrawn from M.F.~Land, J.~Exp.~Biol.~51 (1969) 443")
photo_credit("eg-avalanche-transceiver","Avalanche transceiver","Human figure: based on Pioneer 10 plaque, NASA, public domain. Dipole field: Wikimedia Commons user Geek3, CC-BY") # http://commons.wikimedia.org/wiki/File:VFPt_dipole_thumb.svg
photo_credit("resistor-photo","Resistors","Wikipedia user Afrank99, CC-BY-SA")
photo_credit("melting-witch","Wicked Witch","art by W.W. Denslow, 1900. Quote from \\emph{The Wizard of Oz}, L. Frank Baum, 1900")
photo_credit("iijima","S. Iijima and K. Fujiwara, ``An experiment for the potential blue shift at the Norikura Corona Station,'' Annals of the Tokyo Astronomical Observatory, Second Series, Vol. XVII, 2 (1978) 68","Used here under the U.S.~fair use doctrine")
photo_credit("lightning","Lightning","C. Clark/NOAA photo library, public domain")
photo_credit("millikan","Robert Millikan","Clark Millikan, 1891, public domain")
photo_credit("thomson","J.J. Thomson","Millikan and Gale, 1920.")
photo_credit("curies","Curies","Harper's Monthly, 1904")
photo_credit("becquerel","Becquerel","Millikan and Gale, 1920")
photo_credit("becquerel-plate","Becquerel's photographic plate","public domain")
photo_credit("rutherford","Rutherford","public domain")
photo_credit("nuclear-fuel-pellets","Nuclear fuel pellets","US DOE, public domain")
photo_credit("nuclear-power-plant","Nuclear power plant","Wikipedia user Stefan Kuhn, CC-BY-SA licensed")
photo_credit("fusion-collage","GAMMASPHERE","courtesy of C.J. Lister/R.V.F. Janssens")
photo_credit("fusion-collage","H bomb test","public domain product of US DOE, Ivy Mike test")
photo_credit("fusion-collage","Fatu Hiva Rainforest","Wikipedia user Makemake, CC-BY-SA licensed")
photo_credit("fusion-collage","fusion reactor","``These images may be used free of charge for educational purposes but please use the acknowledgement `photograph courtesy of EFDA-JET'''")
photo_credit("fusion-collage","Sun","SOHO (ESA \\& NASA)")
photo_credit("chernobyl-map","Chernobyl map","CIA Handbook of International Economic Statistics, 1996, public domain")
photo_credit("chernobyl-horses","Horses","(c) 2004 Elena Filatova") #http://www.kiddofspeed.com/chapter8.html
photo_credit("polar-bear","Polar bear","U.S. Fish and Wildlife Service, public domain") #http://commons.wikimedia.org/wiki/Image:Polar_Bear.jpg
photo_credit("crab-nebula","Crab Nebula","``ESO Press Photos may be reproduced, if credit is given to the European Southern Observatory.''")
photo_credit("gymnotus","Knifefish","Courtesy of Greg DeGreef")
photo_credit("ampere","Amp\\`{e}re","Millikan and Gale, 1920")
photo_credit("volta","Volta","Millikan and Gale, 1920")
photo_credit("ohm","Ohm","Millikan and Gale, 1920")
photo_credit("hw-measure-on-printed-circuit","Printed circuit board","Bill Bertram, Wikipedia user Pixel8, CC-BY licensed")
photo_credit("ligo","LIGO","Wikipedia user Umptanum: ``This image is copyrighted. The copyright holder has irrevocably released all rights to it.''")
photo_credit("einsteins-ring-noneuclidean","Einstein's ring","I have lost the information about the source of the bitmapped image. I would be grateful to anyone who could put me in touch with the copyright owners.")
photo_credit("pound-rebka-photos","Pound and Rebka photo","I presume this photo to be in the public domain, since it is unlikely to have had its copyright renewed")
photo_credit("cmb-geometry","Cosmic microwave background image","NASA/WMAP Science Team, public domain") # http://en.wikipedia.org/wiki/File:WMAP_2008.png
photo_credit("hammerhead","Hammerhead shark","Wikimedia Commons user Littlegreenman, public domain")
photo_credit("topo-map","Topographical maps","Flat maps by USGS, public domain; perspective map by Wikipedia user Kbh3rd, CC-BY-SA licensed")
photo_credit("hertz","Hertz","Public domain contemporary photograph")
photo_credit("faraday-portrait","Faraday","Painting by Thomas Phillips, 1842")
photo_credit("capacitors-photo","Capacitors","Wikipedia user de:Benutzer:Honina, CC-BY-SA licensed")
photo_credit("inductors-photo","Inductors","Wikipedia user de:Benutzer:Honina, CC-BY-SA licensed")
photo_credit("crepuscular-rays","Rays of sunlight","Wikipedia user PiccoloNamek, CC-BY-SA")
photo_credit("io","Jupiter and Io","NASA/JPL/University of Arizona")
photo_credit("narcissus","Narcissus","Caravaggio, ca. 1598")
photo_credit("praxinoscope","Praxinoscope","Thomas B. Greenslade, Jr.")
photo_credit("angular-size","Flower","Based on a photo by Wikimedia Commons user Fir0002, CC-BY-SA")
photo_credit("computer-ray-tracing","Ray-traced image","Gilles Tran, Wikimedia Commons, public domain")
photo_credit("newtonian-telescope-eye","Moon","Wikimedia commons image")
photo_credit("short-lens-aberration","Fish-eye lens","Martin D\\\"urrschnabel, CC-BY-SA")
photo_credit("hubble-aberration","Hubble space telescope","NASA, public domain")
photo_credit("peaucellier","Anamorphic image","Wikipedia user Istvan Orosz, CC-BY")
photo_credit("eye-evolution","Flatworm","CC-BY-SA, Alejandro S\\'{a}nchez Alvarado, Planaria.neuro.utah.edu")
photo_credit("eye-evolution","Nautilus","CC-BY-SA, Wikimedia Commons user Opencage, opencage.info")
photo_credit("eye-evolution","Human eye","Joao Estevao A. de Freitas, ``There are no usage restrictions for this photo''")
photo_credit("eye-cross-section","Cross-section of eye","NEI")
photo_credit("eye-anatomy","Eye's anatomy","After a public-domain drawing from NEI")
photo_credit("ulcer","Ulcer","Wikipedia user Aspersions, CC-BY-SA")
photo_credit("refr-derivation","Water wave refracting","Original photo from PSSC")
photo_credit("hw-binoculars","Binoculars","Wikimedia commons, CC-BY-SA")
photo_credit("hw-binoculars","Porro prisms","Redrawn from a figure by Wikipedia user DrBob, CC-BY-SA")
photo_credit("pleiades","Pleiades","NASA/ESA/AURA/Caltech, public domain")
photo_credit("double-slit-water-waves","Diffraction of water waves","Assembled from photos in PSSC")
photo_credit("huygens","Huygens","Contemporary painting?")
photo_credit("double-slit-no-diffraction","Counterfactual lack of diffraction of water waves","Assembled from photos in PSSC")
photo_credit("scaling","Scaling of diffraction","Assembled from photos in PSSC")
photo_credit("double-slit-water-waves-photo","Diffraction of water waves","Assembled from photos in PSSC")
photo_credit("young","Young","Wikimedia Commons, ``After a portrait by Sir Thomas Lawrence, From: Arthur Shuster \\& Arthur E. Shipley: Britain's Heritage of Science. London, 1917''")
photo_credit("double-slit-water-waves","Diffraction of water waves","Assembled from photos in PSSC")
photo_credit("single-slit-water-waves","Single-slit diffraction of water waves","PSSC")
photo_credit("single-slit-simulated-with-three-sources","Simulation of a single slit using three sources","PSSC")
photo_credit("pleiades-closeup","Pleiades","NASA/ESA/AURA/Caltech, public domain")
photo_credit("very-large-array","Radio telescope","Wikipedia user Hajor, CC-BY-SA")
photo_credit("gps-on-bike","GPS","Wikipedia user HawaiianMama, CC-BY license") #http://en.wikipedia.org/wiki/File:GPS_on_smartphone_cycling.JPG
photo_credit("hk-in-cabin","Atomic clock on plane","Copyright 1971, Associated press, used under U.S. fair use exception to copyright law") # Time Magazine, October 18, 1971
photo_credit("football-causality","Football pass","Wikipedia user RMelon, CC-BY-SA licensed") # http://en.wikipedia.org/wiki/File:Orton_To_Wolfe.jpg
photo_credit("joan-of-arc","Joan of Arc holding banner","Ingres, 1854") # http://en.wikipedia.org/wiki/File:Ingres_coronation_charles_vii.jpg
photo_credit("joan-of-arc","Joan of Arc interrogated","Delaroche, 1856") # http://en.wikipedia.org/wiki/File:Joan_of_arc_interrogation.jpg
photo_credit("correspondence-dramatized","Horse","From a public-domain photo by Eadweard Muybridge, 1872")
photo_credit("correspondence-dramatized","Satellite","From a public-domain artist's conception of a GPS satellite, product of NASA") #http://en.wikipedia.org/wiki/File:GPS_Satellite_NASA_art-iif.jpg
photo_credit("cern-muon-storage-ring","Muon storage ring at CERN","(c) 1974 by CERN; used here under the U.S. fair use doctrine")
photo_credit("rhic","Colliding nuclei","courtesy of RHIC")
photo_credit("eclipse","Eclipse","1919, public domain")
photo_credit("newspaper-eclipse","Newspaper headline","1919, public domain")
photo_credit("pet","Photo of PET scanner","Wikipedia user Hg6996, public domain") #http://en.wikipedia.org/wiki/File:16slicePETCT.jpg
photo_credit("pet","Ring of detectors in PET scanner","Wikipedia user Damato, public domain") #http://en.wikipedia.org/wiki/File:PET-detectorsystem_2.png
photo_credit("pet","PET body scan","Jens Langner, public domain") # http://en.wikipedia.org/wiki/File:PET-MIPS-anim.gif
photo_credit("volcano","Mount St. Helens","public-domain image by Austin Post, USGS")
photo_credit("ozone","Ozone maps","NASA/GSFC TOMS Team")
photo_credit("ccd-spot","Digital camera image","courtesy of Lyman Page")
photo_credit("ccd-diffraction","Diffracted photons","courtesy of Lyman Page")
photo_credit("heisenberg","Werner Heisenberg","ca. 1927, believed to be public domain")
photo_credit("hindenburg","Hindenburg","Public domain product of the U.S. Navy")

print "// This file is generated by photocredits.rb.\n"
print JSON.generate($credits)
