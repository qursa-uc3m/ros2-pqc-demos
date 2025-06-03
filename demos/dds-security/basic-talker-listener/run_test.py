#!/usr/bin/env python3
import subprocess
import time
import sys

def run(cmd, show_output=False):
    print(f"Running: {cmd}")
    if show_output:
        return subprocess.run(cmd, shell=True)
    else:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True)

def main():
    print("Starting DDS PQC test")
    
    # Cleanup
    run("docker-compose down -v")
    
    # Build with live output
    print("Building (this may take several minutes)...")
    result = run("docker-compose build", show_output=True)
    if result.returncode != 0:
        print("Build failed")
        return 1
    
    print("Build completed")
    
    # Start cert generator
    print("Generating certificates...")
    result = run("docker-compose run --rm cert-generator /workspace/scripts/certificates/generate_pq_certs.sh")
    if result.returncode != 0:
        print("Certificate generation failed:", result.stderr)
        return 1
    
    print("Certificates generated")
    
    # Start talker and listener containers
    run("docker-compose up -d dds-talker dds-listener")
    time.sleep(2)
    
    # Run test
    print("Starting test...")
    talker = subprocess.Popen("docker exec dds-talker /workspace/scripts/dds/run_talker.sh", 
                             shell=True, stdout=subprocess.PIPE, text=True)
    listener = subprocess.Popen("docker exec dds-listener /workspace/scripts/dds/run_listener.sh", 
                               shell=True, stdout=subprocess.PIPE, text=True)
    
    # Monitor
    messages = 0
    for i in range(30):
        if talker.poll() is None:
            line = talker.stdout.readline()
            if line and "Hello World" in line:
                print(f"[TALKER] {line.strip()}")
                messages += 1
        
        if listener.poll() is None:
            line = listener.stdout.readline()
            if line and "Hello World" in line:
                print(f"[LISTENER] {line.strip()}")
                messages += 1
        
        if i % 5 == 0:
            print(f"Monitoring... {i}/30s")
        
        time.sleep(1)
    
    # Cleanup
    talker.terminate()
    listener.terminate()
    run("docker-compose down -v")
    
    print(f"Test completed. Messages: {messages}")
    return 0 if messages > 0 else 1

if __name__ == "__main__":
    sys.exit(main())