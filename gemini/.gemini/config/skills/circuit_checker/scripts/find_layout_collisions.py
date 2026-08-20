import re
import math
import sys
import os

# Default file path
file_path = None

# If a file path is passed as command-line argument, use it
if len(sys.argv) > 1:
    file_path = sys.argv[1]
else:
    # Otherwise, try to find a .tex file in the current working directory
    tex_files = [f for f in os.listdir('.') if f.endswith('.tex')]
    if tex_files:
        file_path = tex_files[0]

def line_intersection(p1, p2, p3, p4):
    x1, y1 = p1
    x2, y2 = p2
    x3, y3 = p3
    x4, y4 = p4
    
    denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    if abs(denom) < 1e-9:
        return None
        
    ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
    ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom
    
    return ua, ub

def point_to_segment_distance(p, p1, p2):
    x, y = p
    x1, y1 = p1
    x2, y2 = p2
    dx = x2 - x1
    dy = y2 - y1
    if abs(dx) < 1e-9 and abs(dy) < 1e-9:
        return math.sqrt((x - x1)**2 + (y - y1)**2)
    
    t = ((x - x1) * dx + (y - y1) * dy) / (dx*dx + dy*dy)
    t = max(0.0, min(1.0, t))
    proj_x = x1 + t * dx
    proj_y = y1 + t * dy
    return math.sqrt((x - proj_x)**2 + (y - proj_y)**2)

def segment_to_segment_distance(p1, p2, q1, q2):
    res = line_intersection(p1, p2, q1, q2)
    if res:
        ua, ub = res
        if 0 <= ua <= 1 and 0 <= ub <= 1:
            return 0.0
            
    d1 = point_to_segment_distance(p1, q1, q2)
    d2 = point_to_segment_distance(p2, q1, q2)
    d3 = point_to_segment_distance(q1, p1, p2)
    d4 = point_to_segment_distance(q2, p1, p2)
    return min(d1, d2, d3, d4)

def are_collinear(p1, p2, q1, q2):
    dx1 = p2[0] - p1[0]
    dy1 = p2[1] - p1[1]
    dx2 = q2[0] - q1[0]
    dy2 = q2[1] - q1[1]
    # Cross product of directions
    cross = dx1 * dy2 - dy1 * dx2
    if abs(cross) > 1e-2:
        return False
    # Check if q1 lies on the line of p1-p2
    dx3 = q1[0] - p1[0]
    dy3 = q1[1] - p1[1]
    cross2 = dx1 * dy3 - dy1 * dx3
    if abs(cross2) > 1e-2:
        return False
    return True

def get_component_body_segment(c_start, c_end):
    dx = c_end[0] - c_start[0]
    dy = c_end[1] - c_start[1]
    dist = math.sqrt(dx*dx + dy*dy)
    if dist < 0.1:
        return c_start, c_end
    body_size = 0.8
    if dist <= body_size:
        return c_start, c_end
    lead = (dist - body_size) / 2.0
    t1 = lead / dist
    t2 = 1.0 - t1
    p1 = (c_start[0] + t1 * dx, c_start[1] + t1 * dy)
    p2 = (c_start[0] + t2 * dx, c_start[1] + t2 * dy)
    return p1, p2


def parse_coordinate(coord_str, current_pos, opamps, coords, scale):
    coord_str = coord_str.strip()
    if coord_str.startswith('++'):
        coord_str = coord_str[2:].strip()
        relative = True
    elif coord_str.startswith('+'):
        coord_str = coord_str[1:].strip()
        relative = True
    else:
        relative = False
        
    if coord_str.startswith('(') and coord_str.endswith(')'):
        coord_str = coord_str[1:-1].strip()
        
    def parse_dim(s, index):
        s = s.strip()
        try:
            return float(s) * scale
        except ValueError:
            pass
        p = parse_coordinate(s if (s.startswith('(') and s.endswith(')')) else '(' + s + ')', current_pos, opamps, coords, scale)
        if p is not None:
            return p[index]
        return None

    if '-|' in coord_str:
        parts = coord_str.split('-|')
        x = parse_dim(parts[1], 0)
        y = parse_dim(parts[0], 1)
        if x is not None and y is not None:
            return (x, y)
        return None
    elif '|-' in coord_str:
        parts = coord_str.split('|-')
        x = parse_dim(parts[0], 0)
        y = parse_dim(parts[1], 1)
        if x is not None and y is not None:
            return (x, y)
        return None

    m = re.match(r'^(-?\d*(?:\.\d+)?)\s*,\s*(-?\d*(?:\.\d+)?)$', coord_str)
    if m:
        val = (float(m.group(1)) * scale, float(m.group(2)) * scale)
        if relative and current_pos:
            return (current_pos[0] + val[0], current_pos[1] + val[1])
        return val

    if '.' in coord_str:
        node, anchor = coord_str.split('.', 1)
        node = node.strip()
        anchor = anchor.strip()
        if node in opamps:
            op_pos = opamps[node]['pos']
            yscale = opamps[node].get('yscale', 1.0)
            if anchor == '-':
                return (op_pos[0] - 1.19, op_pos[1] + 0.56 * yscale)
            elif anchor == '+':
                return (op_pos[0] - 1.19, op_pos[1] - 0.56 * yscale)
            elif anchor == 'out':
                return (op_pos[0] + 1.19, op_pos[1])
        if node in coords:
            return coords[node]

    if coord_str in coords:
        return coords[coord_str]
    if coord_str in opamps:
        return opamps[coord_str]['pos']
        
    return None

def analyze_schematics():
    if not os.path.exists(file_path):
        print(f"Error: LaTeX file '{file_path}' does not exist.")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    blocks = re.findall(r'\\begin\{circuitikz\}\s*(?:\[([^\]]*)\])?(.*?)\\end\{circuitikz\}', content, re.DOTALL)
    
    if not blocks:
        print("No circuitikz diagrams found in the LaTeX file.")
        return

    for b_idx, (options, block) in enumerate(blocks):
        print(f"\n========================================\nAnalyzing Schematic {b_idx+1}\n========================================")
        
        scale = 1.0
        if options:
            m_scale = re.search(r'scale\s*=\s*([0-9.]+)', options)
            if m_scale:
                scale = float(m_scale.group(1))
                
        opamps = {}
        coords = {}
        
        node_matches = re.finditer(r'\(\s*(-?\d*(?:\.\d+)?)\s*,\s*(-?\d*(?:\.\d+)?)\s*\)\s*node\s*\[([^\]]*)\]\s*\(\s*([a-zA-Z0-9_]+)\s*\)', block)
        for m in node_matches:
            x, y = float(m.group(1)) * scale, float(m.group(2)) * scale
            options_str = m.group(3)
            name = m.group(4)
            yscale = 1.0
            if 'yscale=-1' in options_str:
                yscale = -1.0
            
            if 'op amp' in options_str or 'opamp' in options_str:
                cx, cy = x, y
                if 'anchor=-' in options_str:
                    cx = x + 1.19
                    cy = y - 0.56 * yscale
                elif 'anchor=+' in options_str:
                    cx = x + 1.19
                    cy = y + 0.56 * yscale
                elif 'anchor=out' in options_str:
                    cx = x - 1.19
                    cy = y
                opamps[name] = {'pos': (cx, cy), 'yscale': yscale}
            else:
                coords[name] = (x, y)
                
        ground_nodes = []
        ground_matches = re.finditer(r'\(\s*(-?\d*(?:\.\d+)?)\s*,\s*(-?\d*(?:\.\d+)?)\s*\)\s*node\s*\[\s*ground[^\]]*\]', block)
        for m in ground_matches:
            gx, gy = float(m.group(1)) * scale, float(m.group(2)) * scale
            ground_nodes.append((gx, gy))
                
        text_nodes = []
        text_matches = re.finditer(r'\(\s*(-?\d*(?:\.\d+)?)\s*,\s*(-?\d*(?:\.\d+)?)\s*\)\s*node\s*(?:\[([^\]]*)\])?\s*\{([^}]+)\}', block)
        for m in text_matches:
            tx, ty = float(m.group(1)) * scale, float(m.group(2)) * scale
            opts = m.group(3) or ''
            text = m.group(4)
            if any(opt in opts for opt in ['left', 'right', 'above', 'below', 'draw', 'block']):
                continue
            text_nodes.append(((tx, ty), text))

        draws = re.split(r'\\draw', block)
        wire_segments = []
        components = []
        all_segments = []
        
        for draw_cmd in draws[1:]:
            draw_cmd = draw_cmd.strip().rstrip(';')
            if not draw_cmd:
                continue
                
            tokens = []
            pos = 0
            while pos < len(draw_cmd):
                if draw_cmd[pos] == '%':
                    eol = draw_cmd.find('\n', pos)
                    if eol == -1:
                        break
                    pos = eol + 1
                    continue
                    
                m_coord = re.match(r'^(\+\+\s*\([^)]+\)|\+\s*\([^)]+\)|\([^)]+\))', draw_cmd[pos:])
                if m_coord:
                    tokens.append(('coord', m_coord.group(1), ''))
                    pos += len(m_coord.group(1))
                    continue
                    
                m_op = re.match(r'^(--|\|-|-\||-|)', draw_cmd[pos:])
                if m_op and m_op.group(1):
                    tokens.append(('op', m_op.group(1), ''))
                    pos += len(m_op.group(1))
                    continue
                
                m_to = re.match(r'^(to\s*\[[^\]]*\])', draw_cmd[pos:])
                if m_to:
                    tokens.append(('to', m_to.group(1), ''))
                    pos += len(m_to.group(1))
                    continue
                    
                m_node = re.match(r'^(coordinate\s*\(\s*([a-zA-Z0-9_]+)\s*\)|node\s*\[([^\]]*)\]\s*\(\s*([a-zA-Z0-9_]+)\s*\))', draw_cmd[pos:])
                if m_node:
                    if m_node.group(2):
                        tokens.append(('node_def', m_node.group(2), ''))
                    else:
                        tokens.append(('node_def', m_node.group(4), m_node.group(3)))
                    pos += len(m_node.group(1))
                    continue
                
                pos += 1
            
            current_pos = None
            i = 0
            while i < len(tokens):
                t_type, t_val, t_extra = tokens[i]
                if t_type == 'coord':
                    new_pos = parse_coordinate(t_val, current_pos, opamps, coords, scale)
                    if new_pos is not None:
                        if current_pos is not None and i > 0:
                            prev_op = tokens[i-1]
                            if prev_op[0] == 'op' and prev_op[1] == '--':
                                wire_segments.append((current_pos, new_pos, 'explicit'))
                                all_segments.append((current_pos, new_pos))
                            elif prev_op[0] == 'op' and prev_op[1] == '|-':
                                mid = (current_pos[0], new_pos[1])
                                wire_segments.append((current_pos, mid, 'explicit'))
                                wire_segments.append((mid, new_pos, 'explicit'))
                                all_segments.append((current_pos, mid))
                                all_segments.append((mid, new_pos))
                            elif prev_op[0] == 'op' and prev_op[1] == '-|':
                                mid = (new_pos[0], current_pos[1])
                                wire_segments.append((current_pos, mid, 'explicit'))
                                wire_segments.append((mid, new_pos, 'explicit'))
                                all_segments.append((current_pos, mid))
                                all_segments.append((mid, new_pos))
                            elif prev_op[0] == 'to':
                                to_opts = prev_op[1]
                                if 'short' in to_opts or 'wire' in to_opts:
                                    wire_segments.append((current_pos, new_pos, 'short'))
                                    all_segments.append((current_pos, new_pos))
                                else:
                                    dx = new_pos[0] - current_pos[0]
                                    dy = new_pos[1] - current_pos[1]
                                    dist = math.sqrt(dx*dx + dy*dy)
                                    if dist > 0.001:
                                        mx = current_pos[0] + dx/2
                                        my = current_pos[1] + dy/2
                                        comp_len = min(0.8 * scale, dist * 0.8)
                                        cx = (dx / dist) * (comp_len / 2)
                                        cy = (dy / dist) * (comp_len / 2)
                                        comp_start = (mx - cx, my - cy)
                                        comp_end = (mx + cx, my + cy)
                                        components.append((to_opts, comp_start, comp_end, (mx, my), current_pos, new_pos))
                                        wire_segments.append((current_pos, comp_start, 'lead'))
                                        wire_segments.append((comp_end, new_pos, 'lead'))
                                        all_segments.append((current_pos, new_pos))
                        current_pos = new_pos
                elif t_type == 'node_def':
                    name = t_val
                    options_str = t_extra
                    if current_pos is not None:
                        coords[name] = current_pos
                        if options_str and ('op amp' in options_str or 'opamp' in options_str):
                            yscale = 1.0
                            if 'yscale=-1' in options_str:
                                yscale = -1.0
                            x, y = current_pos
                            cx, cy = x, y
                            if 'anchor=-' in options_str:
                                cx = x + 1.19
                                cy = y - 0.56 * yscale
                            elif 'anchor=+' in options_str:
                                cx = x + 1.19
                                cy = y + 0.56 * yscale
                            elif 'anchor=out' in options_str:
                                cx = x - 1.19
                                cy = y
                            opamps[name] = {'pos': (cx, cy), 'yscale': yscale}
                i += 1

        # 3. Perform Style Checks
        errors = []
        
        # A. Bounding-Box/Wire Collisions
        for idx1, s1 in enumerate(wire_segments):
            for idx2, s2 in enumerate(wire_segments[idx1+1:]):
                res = line_intersection(s1[0], s1[1], s2[0], s2[1])
                if res:
                    ua, ub = res
                    if 0.001 < ua < 0.999 and 0.001 < ub < 0.999:
                        ix = s1[0][0] + ua * (s1[1][0] - s1[0][0])
                        iy = s1[0][1] + ua * (s1[1][1] - s1[0][1])
                        errors.append(f"Wire-Wire Crossing at ({ix/scale:.2f}, {iy/scale:.2f})")
                        
        for s in wire_segments:
            for comp in components:
                to_opts, c_start, c_end, c_center, *rest = comp
                res = line_intersection(s[0], s[1], c_start, c_end)
                if res:
                    ua, ub = res
                    if 0.001 < ua < 0.999 and -0.001 <= ub <= 1.001:
                        ix = s[0][0] + ua * (s[1][0] - s[0][0])
                        iy = s[0][1] + ua * (s[1][1] - s[0][1])
                        errors.append(f"Wire cutting through component body ({to_opts}) at ({ix/scale:.2f}, {iy/scale:.2f})")
                        
        for name, op in opamps.items():
            ox, oy = op['pos']
            pins = [
                (ox - 1.19, oy + 0.56 * op['yscale']),
                (ox - 1.19, oy - 0.56 * op['yscale']),
                (ox + 1.19, oy)
            ]
            for s in wire_segments:
                mx = (s[0][0] + s[1][0]) / 2.0
                my = (s[0][1] + s[1][1]) / 2.0
                if ox - 1.15 < mx < ox + 1.15 and oy - 0.45 < my < oy + 0.45:
                    is_lead = False
                    for pin in pins:
                        if (abs(s[0][0] - pin[0]) < 0.01 and abs(s[1][0] - pin[0]) < 0.01) or \
                           (abs(s[0][0] - pin[0]) < 0.01 and abs(s[0][1] - pin[1]) < 0.01) or \
                           (abs(s[1][0] - pin[0]) < 0.01 and abs(s[1][1] - pin[1]) < 0.01):
                            is_lead = True
                            break
                    if not is_lead:
                        errors.append(f"Wire segment crosses inside Op-Amp '{name}' body")
            
            # Direct connection check
            for pin_name, pin_pos in [('-', (ox - 1.19, oy + 0.56 * op['yscale'])),
                                      ('+', (ox - 1.19, oy - 0.56 * op['yscale'])),
                                      ('out', (ox + 1.19, oy))]:
                for comp in components:
                    to_opts, c_start, c_end, c_center, *rest = comp
                    if 'short' in to_opts or 'wire' in to_opts:
                        continue
                    dist_start = math.sqrt((c_start[0] - pin_pos[0])**2 + (c_start[1] - pin_pos[1])**2)
                    dist_end = math.sqrt((c_end[0] - pin_pos[0])**2 + (c_end[1] - pin_pos[1])**2)
                    if dist_start < 0.01 or dist_end < 0.01:
                        errors.append(f"Component '{to_opts}' is directly connected to Op-Amp '{name}' terminal '{pin_name}' without a lead wire")
            
            # Op-Amp body clearance check
            for comp in components:
                to_opts, c_start, c_end, c_center, *rest = comp
                if 'short' in to_opts or 'wire' in to_opts:
                    continue
                dist = math.sqrt((c_center[0] - ox)**2 + (c_center[1] - oy)**2)
                if dist < 1.8 * scale:
                    errors.append(f"Component '{to_opts}' is too close to Op-Amp '{name}' center (distance={dist/scale:.2f} < 1.8)")

        # B. Angle Check - Only horizontal or vertical lines allowed
        if b_idx + 1 != 13: # Exclude Wheatstone bridge (Schematic 13) from diagonal check
            for s in wire_segments:
                s_start, s_end, s_type = s
                dx = abs(s_end[0] - s_start[0])
                dy = abs(s_end[1] - s_start[1])
                if dx > 0.02 and dy > 0.02:
                    angle_deg = math.degrees(math.atan2(dy, dx))
                    errors.append(f"Diagonal wire segment detected: angle={angle_deg:.1f}° from ({s_start[0]/scale:.2f}, {s_start[1]/scale:.2f}) to ({s_end[0]/scale:.2f}, {s_end[1]/scale:.2f})")

        # C. Strict Spacing Check (Minimum 1.5 units distance between parallel traces)
        vert_segments = []
        horiz_segments = []
        for s in all_segments:
            dx = abs(s[1][0] - s[0][0])
            dy = abs(s[1][1] - s[0][1])
            if dx < 0.01 and dy > 0.01:
                vert_segments.append((s[0][0], min(s[0][1], s[1][1]), max(s[0][1], s[1][1])))
            elif dy < 0.01 and dx > 0.01:
                horiz_segments.append((s[0][1], min(s[0][0], s[1][0]), max(s[0][0], s[1][0])))
                
        for idx1, v1 in enumerate(vert_segments):
            x1, y1_min, y1_max = v1
            for v2 in vert_segments[idx1+1:]:
                x2, y2_min, y2_max = v2
                overlap_y = max(0, min(y1_max, y2_max) - max(y1_min, y2_min))
                if overlap_y > 0.05 * scale:
                    dist_x = abs(x1 - x2)
                    if 0.01 < dist_x < 1.49 * scale:
                        errors.append(f"Vertical paths at x={x1/scale:.2f} and x={x2/scale:.2f} are too close (distance={dist_x/scale:.2f} < 1.5)")
                        
        for idx1, h1 in enumerate(horiz_segments):
            y1, x1_min, x1_max = h1
            for h2 in horiz_segments[idx1+1:]:
                y2, x2_min, x2_max = h2
                overlap_x = max(0, min(x1_max, x2_max) - max(x1_min, x2_min))
                if overlap_x > 0.05 * scale:
                    dist_y = abs(y1 - y2)
                    if 0.01 < dist_y < 1.49 * scale:
                        is_opamp_inputs = False
                        for name, op in opamps.items():
                            oy = op['pos'][1]
                            pin1 = oy + 0.56 * op['yscale']
                            pin2 = oy - 0.56 * op['yscale']
                            if (abs(y1 - pin1) < 0.05 and abs(y2 - pin2) < 0.05) or \
                               (abs(y1 - pin2) < 0.05 and abs(y2 - pin1) < 0.05):
                                is_opamp_inputs = True
                                break
                        if not is_opamp_inputs:
                            errors.append(f"Horizontal paths at y={y1/scale:.2f} and y={y2/scale:.2f} are too close (distance={dist_y/scale:.2f} < 1.5)")

        # D. Component-Component Distance Check (strict threshold 1.2)
        for idx1, comp1 in enumerate(components):
            to_opts1, c_start1, c_end1, c_center1, *rest1 = comp1
            if 'short' in to_opts1 or 'wire' in to_opts1:
                continue
            for comp2 in components[idx1+1:]:
                to_opts2, c_start2, c_end2, c_center2, *rest2 = comp2
                if 'short' in to_opts2 or 'wire' in to_opts2:
                    continue
                dist = math.sqrt((c_center1[0] - c_center2[0])**2 + (c_center1[1] - c_center2[1])**2)
                if dist < 1.2 * scale:
                    errors.append(f"Components '{to_opts1}' and '{to_opts2}' are too close (distance={dist/scale:.2f} < 1.2)")

        # E. Wire-Component Proximity Check (except collinear/connecting wires)
        for s in wire_segments:
            for comp in components:
                to_opts, c_start, c_end, c_center, orig_start, orig_end = comp
                if 'short' in to_opts or 'wire' in to_opts:
                    continue
                # If the wire is connected directly to the component terminals, ignore it
                if math.sqrt((s[0][0] - orig_start[0])**2 + (s[0][1] - orig_start[1])**2) < 0.01 or \
                   math.sqrt((s[1][0] - orig_start[0])**2 + (s[1][1] - orig_start[1])**2) < 0.01 or \
                   math.sqrt((s[0][0] - orig_end[0])**2 + (s[0][1] - orig_end[1])**2) < 0.01 or \
                   math.sqrt((s[1][0] - orig_end[0])**2 + (s[1][1] - orig_end[1])**2) < 0.01:
                    continue
                if are_collinear(s[0], s[1], c_start, c_end):
                    continue
                body_p1, body_p2 = get_component_body_segment(c_start, c_end)
                dist = segment_to_segment_distance(s[0], s[1], body_p1, body_p2)
                if dist < 0.7 * scale:
                    errors.append(f"Wire segment from ({s[0][0]/scale:.2f}, {s[0][1]/scale:.2f}) to ({s[1][0]/scale:.2f}, {s[1][1]/scale:.2f}) is too close to component '{to_opts}' body (distance={dist/scale:.2f} < 0.7)")

        # F. Text Node Clearance Check
        for (tx, ty), text in text_nodes:
            # Check distance to component centers
            for comp in components:
                to_opts, c_start, c_end, c_center, *rest = comp
                if 'short' in to_opts or 'wire' in to_opts:
                    continue
                dist = math.sqrt((tx - c_center[0])**2 + (ty - c_center[1])**2)
                if dist < 1.4 * scale:
                    errors.append(f"Text node '{text}' is too close to component '{to_opts}' (distance={dist/scale:.2f} < 1.4)")
            # Check distance to ground nodes
            for gx, gy in ground_nodes:
                dist_x = abs(tx - gx)
                dist_y = abs(ty - gy)
                # Approximate horizontal text half-width + ground symbol radius
                text_width = (len(text) * 0.08 + 0.4) * scale
                if dist_x < text_width and dist_y < 1.8 * scale:
                    errors.append(f"Text node '{text}' is too close to/overlaps ground node at ({gx/scale:.2f}, {gy/scale:.2f})")
            # Check distance to wire segments
            for s in wire_segments:
                dist = point_to_segment_distance((tx, ty), s[0], s[1])
                if dist < 0.6 * scale:
                    errors.append(f"Text node '{text}' is too close to wire segment (distance={dist/scale:.2f} < 0.6)")

        # G. Wire Segment Length Check
        for s in wire_segments:
            s_start, s_end, s_type = s
            dx = abs(s_end[0] - s_start[0])
            dy = abs(s_end[1] - s_start[1])
            length = math.sqrt(dx*dx + dy*dy)
            
            # Default thresholds
            if s_type == 'explicit':
                threshold = 0.3 * scale
            elif s_type == 'lead':
                if b_idx + 1 in [5, 6]:
                    threshold = 0.65 * scale  # Enforce minimum lead length of 0.65 unscaled units for Schematic 5 and 6
                else:
                    threshold = 0.35 * scale  # Standard threshold for other schematics to avoid false positives
            else:
                threshold = 0.35 * scale
                
            # Specific check for Schematic 5 to catch short segments around opamp inputs and Rg
            if b_idx + 1 == 5:
                # Check if this segment connects to an opamp inverting terminal
                is_opamp_inverting_conn = False
                for name, op in opamps.items():
                    ox, oy = op['pos']
                    pin = (ox - 1.2, oy + 0.5 * op['yscale'])
                    if (abs(s_start[0] - pin[0]) < 0.01 and abs(s_start[1] - pin[1]) < 0.01) or \
                       (abs(s_end[0] - pin[0]) < 0.01 and abs(s_end[1] - pin[1]) < 0.01):
                        is_opamp_inverting_conn = True
                        break
                
                if is_opamp_inverting_conn:
                    if dx > 0.01 and dy < 0.01:  # Horizontal
                        threshold = 2.0 * scale
                    elif dy > 0.01 and dx < 0.01:  # Vertical
                        threshold = 1.5 * scale
            
            if length < threshold - 0.01:
                errors.append(f"Wire segment of type '{s_type}' is too short (length={length/scale:.2f} < {threshold/scale:.1f})")

        if errors:
            print(f"  [ERRORS FOUND]:")
            for err in sorted(list(set(errors))):
                print(f"    - {err}")
        else:
            print("  Schematic layout is clean, spacious, and 100% compliant!")

if __name__ == '__main__':
    analyze_schematics()
