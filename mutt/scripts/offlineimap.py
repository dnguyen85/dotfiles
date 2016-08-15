#!/usr/bin/python
import re, subprocess

def get_lastpass_pass(account=None, entry=None):
    command = "lpass show --sync=auto --password %s" % entry
    try: 
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        outtext = [l for l in output.splitlines()][0]
    except subprocess.CalledProcessError:
        # print "Calling lastpass fails, retry now!\n"
        login_prompt = "lpass login %s" % account
        # Login
        output = subprocess.check_output(login_prompt, shell=True, stderr=subprocess.STDOUT)
        # Get the credentials
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        outtext = [l for l in output.splitlines()][0]

    return re.match(r"(.*)", outtext).group(1)

def fastmail_local_to_remote(folder):
    """
    Perform name translation between local and remote
    """
    if (folder != 'INBOX'):
        return 'INBOX.' + folder
    else:
        return folder

if __name__ == '__main__':
    print get_lastpass_pass(account="danhnguyen04@gmail.com", entry="fastmail.com")
