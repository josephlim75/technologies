## Dialog Continue in Background

http://invisible-island.net/dialog/dialog-figures.html#demo_gauge

      status="Initializing"    
      (echo 1
       sleep 1
       status="Loading"
       echo 30
       sleep 1
       echo 90
       sleep 1
       echo 100
      ) | dialog --gauge $status 10 40
      
      
- You need to feed the percentages to the gauge via standard input. Try this to see how it works:

    for i in $(seq 1 100); do echo $i; sleep 0.1; done | \
      dialog --gauge "Example" 10 50

- So, in your case, just do your work in a subshell, outputting a percentage number every now and then, and pipe it to dialog. Something like this:

    (echo 1
     sleep 1
     echo 30
     sleep 1
     echo 90
     sleep 1
     echo 100
    ) | dialog --gauge "Working hard..." 10 40
    (where every sleep 1 represents some real work, of course...).

- EDIT: Changing the text

- To change the text, you output XXX, a number, then the new text, then XXX again. Example:

    (echo 30
     sleep 1
     echo XXX; echo 60; echo "New text"; echo XXX
     sleep 1
     echo 100
    ) | dialog --gauge "Working hard..." 10 40

- You need to read dialog's manual page; everything is explained there.      

- Dialog inputbox
    echo -e "\033[0;0m                   "  # Change default/current background color
    dialog --inputbox "test" 20 0
    
- Dialog Menu

    dialog --title 'Example' --default-item '2' --menu 'Select:' 0 0 0 1 'ABC' 2 'DEF' 3 'GHI'    
    
- Dialog resource/configuration

    ~/.dialogrc
    DIALOGRC environment