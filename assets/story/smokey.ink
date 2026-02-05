EXTERNAL GET_MEAL_COUNT()
EXTERNAL PROMPT_MEAL_ID()
EXTERNAL GET_HOTBAR_AMOUNT(item_id)
EXTERNAL PROMPT_MEAL_REWARD(item_id)
EXTERNAL DO_TRADE(meal_id, amount, reward_id)
EXTERNAL HINT_AVAILABLE()

EXTERNAL PROMPT_AMOUNT(max_amount)
EXTERNAL PROMPT_CONFIRM()

=== start ===
    {Hi Clementine!|Make sure you look in your recipe book. Then flip to the campfire page!|I little birdie told me "you can right click to move one item. Or left click to move a stack!" I must have been dreaming...|Remember to craft a chest to hold your things.|If you hold a pickaxe in your hand you can break rocks!|That birdie came back in my dreams. It said "You can press the number keys to hold an inventory item in your hand." Total nonsense!|{&Oh, hey Clementine.|What's up Clementine?|Lovely weather huh... I guess it never changes.|My tummy is rumbling.}} #smokey
    #wait
    -> trade_meal

=== trade_meal ===
    { GET_MEAL_COUNT() == 0: -> failed}
    {&Do you have anything to eat?|I'm hungry, you got anything?|Have you cooked anything recently?|Got anything to eat?|Could I have a sweet treat?}
    ~ temp meal_id = PROMPT_MEAL_ID()
    { meal_id == "": -> failed }
    
    ~ temp amount = GET_HOTBAR_AMOUNT(meal_id)
    
    { amount > 1:
        How many <item={meal_id}> {&could you spare|are you offering|will you give me}?
        ~ amount = PROMPT_AMOUNT(amount)
    }
    
    {&Can I give you something in exchange?|What do you want in return?}
    ~ temp reward_id = PROMPT_MEAL_REWARD(meal_id)
    
    {&That's|So|That will be} {amount} <item={meal_id}> for {amount} <item={reward_id}>?
    { PROMPT_CONFIRM():
        { DO_TRADE(meal_id, amount, reward_id):
            -> succeeded
        - else:
            -> error
        }
    - else:
        -> failed
    }
    
    = succeeded
        {&Thanks so much!|This tastes really good!|I needed a snack.|Yum! This is good.}
        { HINT_AVAILABLE():
            {Eclipse has a new idea, you should call her.|You should call Eclipse.|Eclipse has an idea.}
        }
        -> END
        
    = failed
        {&I guess you don't have any food.|No food today, huh.|Maybe you'll make something to eat later...}
        -> END
    
    = error
        You seem to have moved the food out of your inventory. I can't take it.
        -> END
