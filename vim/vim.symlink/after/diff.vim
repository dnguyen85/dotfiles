" Set wrap automatically in vimdiff
if &diff 
    setlocal wrap< 
    set diffopt=filler,context:1000,iwhite
endif

