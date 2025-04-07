#!/usr/bin/env python3

import json
import subprocess
import re

def get_container_ids():
    """Get IDs of all running containers"""
    result = subprocess.run(['docker', 'ps', '-q'], capture_output=True, text=True)
    return result.stdout.strip().split('\n')

def format_ports(tcp_ports, udp_ports):
    """Format port lists with ranges and proper separation"""
    
    def create_port_ranges(ports):
        if not ports:
            return ""
            
        # Convert to integers and sort
        ports = sorted([int(p) for p in ports])
        
        ranges = []
        range_start = None
        range_end = None
        
        for port in ports:
            if range_start is None:
                range_start = range_end = port
            elif port == range_end + 1:
                range_end = port
            else:
                # End current range
                if range_start == range_end:
                    ranges.append(str(range_start))
                else:
                    ranges.append(f"{range_start}:{range_end}")
                range_start = range_end = port
        
        # Add the last range
        if range_start is not None:
            if range_start == range_end:
                ranges.append(str(range_start))
            else:
                ranges.append(f"{range_start}:{range_end}")
        
        return ','.join(ranges)
    
    tcp_formatted = create_port_ranges(tcp_ports)
    udp_formatted = create_port_ranges(udp_ports)
    
    if tcp_formatted and udp_formatted:
        return f"{tcp_formatted} / {udp_formatted}"
    else:
        return tcp_formatted or udp_formatted

def main():
    # Print header
    print(f"{'CONTAINER ID':<15} {'IMAGE':<20} {'TAG':<20} {'PORTS'}")
    print(f"{'-'*12:<15} {'-'*5:<20} {'-'*3:<20} {'-'*5}")
    
    # Process each container
    for container_id in get_container_ids():
        if not container_id:
            continue
            
        # Get short container ID
        short_id = container_id[:12]
        
        # Get container details
        inspect_cmd = ['docker', 'inspect', container_id]
        result = subprocess.run(inspect_cmd, capture_output=True, text=True)
        container_info = json.loads(result.stdout)[0]
        
        # Get image name and tag
        full_image = container_info['Config']['Image']
        # Strip registry and path
        image_with_tag = re.sub(r'.*/([^/]+)$', r'\1', full_image)
        
        # Split image and tag
        if ':' in image_with_tag:
            image, tag = image_with_tag.split(':', 1)
        else:
            image, tag = image_with_tag, "latest"
        
        # Get exposed ports
        exposed_ports = container_info['Config'].get('ExposedPorts', {})
        tcp_ports = []
        udp_ports = []
        
        for port_proto in exposed_ports:
            port, proto = port_proto.split('/')
            if proto == 'tcp':
                tcp_ports.append(port)
            elif proto == 'udp':
                udp_ports.append(port)
        
        ports = format_ports(tcp_ports, udp_ports)
        
        # Print container info
        print(f"{short_id:<15} {image:<20} {tag:<20} {ports}")

if __name__ == "__main__":
    main()
