#!/usr/bin/env python3
import os
import webbrowser
import subprocess
from time import sleep
import platform
import socket
from datetime import datetime

# Color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    END = '\033[0m'
    BOLD = '\033[1m'

BANNER = f"""{Colors.BLUE}
 ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗ ██╗   ██╗███████╗     █████╗ ██╗       ███████╗███╗   ██╗██╗   ██╗
██╔════╝██║  ██║██║████╗  ██║██╔═══██╗██║   ██║██╔════╝    ██╔══██╗██║       ██╔════╝████╗  ██║██║   ██║
██║     ███████║██║██╔██╗ ██║██║   ██║██║   ██║█████╗█████╗███████║██║       █████╗  ██╔██╗ ██║██║   ██║
██║     ██╔══██║██║██║╚██╗██║██║▄▄ ██║██║   ██║██╔══╝╚════╝██╔══██║██║       ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝
╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝╚██████╔╝███████╗    ██║  ██║██║    ██╗███████╗██║ ╚████║ ╚████╔╝ 
 ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚══▀▀═╝  ╚═════╝ ╚══════╝    ╚═╝  ╚═╝╚═╝    ╚═╝╚══════╝╚═╝  ╚═══╝  ╚═══╝  
                                                                                                        
{Colors.END}"""

SERVICES = {
    "1": {
        "name": "N8N Workflows (5678)",
        "url": "http://localhost:5678",
        "container": "n8n-app",
        "health": "/health"
    },
    "2": {
        "name": "Open WebUI (3000)",
        "url": "http://localhost:3000",
        "container": "open-webui",
        "health": "/"
    },
    "3": {
        "name": "Browser Automation (8000)",
        "url": "http://localhost:8000",
        "container": "browser-automation",
        "health": "/health"
    },
    "4": {
        "name": "MCPO Proxy (9000)",
        "url": "http://localhost:9000",
        "container": "mcpo-proxy",
        "health": "/status"
    },
    "5": {
        "name": "Ollama API (11434)",
        "url": "http://localhost:11434",
        "container": "ollama-server",
        "health": "/"
    },
    "6": {
        "name": "PostgreSQL Adminer (8080)",
        "url": "http://localhost:8080",
        "container": "",
        "health": ""
    },
    "7": {
        "name": "Exit",
        "url": "",
        "container": "",
        "health": ""
    }
}

def check_port(port):
    """Check if a port is available locally"""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def check_container_status(container_name):
    """Check if container is running and healthy"""
    if not container_name:
        return False
        
    try:
        result = subprocess.run(
            ["docker", "inspect", "--format='{{.State.Status}}'", container_name],
            capture_output=True, text=True
        )
        return "running" in result.stdout.lower()
    except:
        return False

def check_service_health(url):
    """Check if service endpoint is responsive"""
    try:
        response = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "'%{http_code}'", url],
            capture_output=True, text=True
        )
        return "200" in response.stdout
    except:
        return False

def print_menu():
    """Display the interactive menu"""
    print(f"\n{Colors.BOLD}KhuChinQue AI Framework - Available Services:{Colors.END}")
    for key, service in SERVICES.items():
        if key == "7":
            print(f"{key}. {service['name']}")
            continue
            
        container_status = check_container_status(service["container"])
        port_status = check_port(int(service["url"].split(":")[-1].split("/")[0])) if service["url"] else False
        health_status = check_service_health(service["url"] + service["health"]) if service["health"] else False
        
        status = (f"{Colors.GREEN}✓{Colors.END}" if container_status else f"{Colors.RED}✗{Colors.END}") + \
                 (f"{Colors.GREEN}✓{Colors.END}" if health_status else f"{Colors.RED}✗{Colors.END}") + \
                 (f"{Colors.GREEN}✓{Colors.END}" if port_status else f"{Colors.RED}✗{Colors.END}")
        
        print(f"{key}. {service['name']} [Container: {status[0:7]}, Health: {status[7:14]}, Port: {status[14:]}]")

def open_service(service):
    """Handle service startup and access"""
    if not service["url"]:
        return

    print(f"\n{Colors.YELLOW}Attempting to access {service['name']}...{Colors.END}")
    
    if service["container"] and not check_container_status(service["container"]):
        print(f"{Colors.RED}⚠️ Container {service['container']} is not running!{Colors.END}")
        start = input(f"Do you want to start it? (y/n): ").lower()
        if start == 'y':
            print(f"{Colors.YELLOW}Starting {service['container']}...{Colors.END}")
            os.system(f"docker start {service['container']}")
            sleep(3)  # Wait for service to start
    
    if platform.system() == 'Linux' and 'DISPLAY' not in os.environ:
        print(f"{Colors.YELLOW}No display detected. Opening in text browser...{Colors.END}")
        os.system(f"curl {service['url']} | less")
    else:
        webbrowser.open(service['url'])
        print(f"{Colors.GREEN}✔ Opened {service['url']} in your browser{Colors.END}")

def system_info():
    """Display system and Docker information"""
    print(f"\n{Colors.BOLD}System Information:{Colors.END}")
    os.system("docker --version")
    os.system("docker-compose --version")
    print(f"Python: {platform.python_version()}")
    print(f"OS: {platform.system()} {platform.release()}")
    print(f"Current Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

def main():
    print(BANNER)
    print(f"{Colors.BOLD}Welcome to KhuChinQue AI Framework{Colors.END}")
    system_info()
    
    while True:
        print_menu()
        choice = input("\nSelect a service (1-7): ")
        
        if choice == "7":
            print(f"{Colors.YELLOW}Exiting...{Colors.END}")
            break
            
        if choice in SERVICES:
            open_service(SERVICES[choice])
        else:
            print(f"{Colors.RED}Invalid choice. Please try again.{Colors.END}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.RED}Operation cancelled by user.{Colors.END}")
    except Exception as e:
        print(f"\n{Colors.RED}Error: {str(e)}{Colors.END}")
