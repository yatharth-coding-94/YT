# update.py
import os
import shutil

def remove_old_tool():
    if os.path.exists("kali"):
        print("[*] Removing old 'kali' directory...")
        shutil.rmtree("kali")
        print("[+] Removed successfully.")
    else:
        print("[*] 'kali' directory not found, skipping removal.")

def clone_new_tool():
    print("[*] Cloning new tool from GitHub...")
    os.system("git clone https://github.com/riti-web/Kali.git")
    print("[+] Cloned successfully.")

if __name__ == "__main__":
    remove_old_tool()
    clone_new_tool()