EXTERNAL USE_HINT()
EXTERNAL GET_HINT_RECIPE_ID()
EXTERNAL GET_UNCRAFTED_ITEM_ID()
EXTERNAL GET_RECIPE_INGREDIENTS(recipe_id)
EXTERNAL GET_RECIPE_RESULT(recipe_id)
EXTERNAL DISCOVER_RECIPE(recipe_id)
EXTERNAL EMIT_KISS()

EXTERNAL HINT_AVAILABLE()
EXTERNAL PROMPT_CONFIRM()

=== start ===
    {&HssssSHhhh|Pshhhhhhh|KrRRZZzz|ShhhHHhh|Fsssssshh} #radio
    #wait
    {&Hello Clementine!|Hey sweetie.|Hey, it's so dusty up here.|OMG, hey Clementine!|I was just thinking of you.} #eclipse
    {!Please keep Smokey well fed for me while I'm away.|I'm finding so many new rocks up here!|I fell into a crator the other day.||||I like working on the moon, but I miss you.|||You know, I left my old ship, the <name=SS Catnip>, back on Earth.|The <name=SS Catnip>... is completly run down. I forgot to mention that.}
    #wait
    
    { USE_HINT():
        -> give_hint
    - else:
        {&I'm busy collecting moon dust samples. Talk later?|I'll get back to it. Please make sure my cousin Smokey is well fed.|I should get back to work. It's nice to hear you.|I'm going to go, these rocks don't study themselves.}
        -> END
    }

=== in_person ===
    Oh my gods Clementine, how did you get here?! #eclipse
    #wait
    You repaired the <name=SS Catnip>! How did... never mind that.
    #wait
    Come here, I missed you.
    ~ EMIT_KISS()
    -> END

=== give_hint ===
    -> recipe

    = recipe
        ~ temp recipe_id = GET_HINT_RECIPE_ID()
        { recipe_id == "": -> uncrafted}
        
        ~ temp ingredients = GET_RECIPE_INGREDIENTS(recipe_id)
        ~ temp result = GET_RECIPE_RESULT(recipe_id)
        
        I just discovered a recipe for {result}.
        {
        - recipe_id ? "assembly/":
            Assemble {ingredients} in a workstation.
        - recipe_id ? "campfire/":
            Cook {ingredients} in a campfire.
        - recipe_id ? "smelter/":
            Refine {ingredients} in a smelter.
        - else:
            Use {ingredients}... somehow. I forgot.
        }
        #wait
        {!I've added the instruction to your recipe book!|It's been added to your recipe book.}
        ~ DISCOVER_RECIPE(recipe_id)
        -> exit
        
    = uncrafted
        ~ temp item_id = GET_UNCRAFTED_ITEM_ID()
        { item_id == "": -> explore}
        
        Have you {&tried making|crafted} a <item={item_id}>?
        {&It might give me some new ideas!|It could be useful.|I think it's a neat item.}
        -> END
    
    = explore
        {&Try breaking new rocks with a pickaxe.|You should try sailing with a raft. Just hold it in your hand, and drop it by the shore|You can bring a spear to the dock to catch fish! You just need to hold it in your hand.|You should try exploring, there might be something new out there!|I think it might be possible to repair The <name=SS Catnip>.}
        -> END
    
    = exit
        { HINT_AVAILABLE():
            I have more ideas if you want to hear.
            { PROMPT_CONFIRM():
                ~ USE_HINT()
                -> give_hint
             - else:
                Talk later! :3
                -> END
            }
         - else:
            I don't have more ideas. Let's talk later!
        }
        -> END