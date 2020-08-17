## Select entire line
- **`V`** (Capital V) 
- **`v`** (lowercase v) is to select character range    
- **`y`** (Yank or copy)     
     
## Select entire text
- `g` `g` `"` `*` `y` `G`


To turn off autoindent when you paste code, there's a special "paste" mode.

  :set paste

Then paste your code. Note that the text in the tooltip now says -- INSERT (paste) --.

After you pasted your code, turn off the paste-mode, so that auto-indenting when you type works correctly again.

:set nopaste

However, I always found that cumbersome. That's why I map <F3> such that it can switch between paste and nopaste modes while editing the text! I add this to .vimrc

set pastetoggle=<F3>