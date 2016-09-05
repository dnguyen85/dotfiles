#!/usr/bin/python2.7

import i3
outputs = i3.get_outputs()

# Move all workspace to the right, if output is active
for i in range(len(outputs)):
    if (outputs[i]['active'] == True):
        i3.workspace(outputs[i]['current_workspace'])
        i3.command('move workspace to output right')


