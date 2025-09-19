#!/usr/bin/env python3
"""
Script to properly add CAF sound files to the Xcode project.
This will add the files to both PBXFileReference and PBXBuildFile sections,
and include them in the Resources build phase.
"""

import re
import uuid

def generate_xcode_uuid():
    """Generate a 24-character UUID in the format used by Xcode."""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_sounds_to_xcode():
    project_file = 'ios/Runner.xcodeproj/project.pbxproj'
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Sound files to add
    sound_files = ['alarm_1.caf', 'chime_1.caf', 'bell_1.caf']
    
    # Generate UUIDs for each file (2 UUIDs per file: one for file reference, one for build file)
    file_uuids = {}
    build_uuids = {}
    
    for sound_file in sound_files:
        file_uuids[sound_file] = generate_xcode_uuid()
        build_uuids[sound_file] = generate_xcode_uuid()
    
    # 1. Add to PBXBuildFile section
    build_file_section = ""
    for sound_file in sound_files:
        build_file_section += f"\t\t{build_uuids[sound_file]} /* {sound_file} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_uuids[sound_file]} /* {sound_file} */; }};\n"
    
    # Find the end of PBXBuildFile section and add our entries
    build_file_pattern = r'(/* End PBXBuildFile section */)'
    content = re.sub(build_file_pattern, build_file_section + r'\1', content)
    
    # 2. Add to PBXFileReference section
    file_ref_section = ""
    for sound_file in sound_files:
        file_ref_section += f"\t\t{file_uuids[sound_file]} /* {sound_file} */ = {{isa = PBXFileReference; lastKnownFileType = audio; path = {sound_file}; sourceTree = \"<group>\"; }};\n"
    
    # Find the end of PBXFileReference section and add our entries
    file_ref_pattern = r'(/* End PBXFileReference section */)'
    content = re.sub(file_ref_pattern, file_ref_section + r'\1', content)
    
    # 3. Add to Runner group (find the Runner group children and add our files)
    runner_group_pattern = r'(97C146F01CF9000F007C117D /\* Runner \*/ = \{[^}]+children = \([^)]+)((\s+[A-F0-9]+[^,;]+[,;])*)'
    
    # Find the Runner group
    runner_match = re.search(runner_group_pattern, content, re.DOTALL)
    if runner_match:
        children_section = runner_match.group(2)
        new_children = children_section
        for sound_file in sound_files:
            new_children += f"\n\t\t\t\t{file_uuids[sound_file]} /* {sound_file} */,"
        
        content = content.replace(runner_match.group(2), new_children)
    
    # 4. Add to Resources build phase
    resources_pattern = r'(/* Resources */ = \{[^}]+files = \([^)]+)((\s+[A-F0-9]+[^,;]+[,;])*)'
    
    resources_match = re.search(resources_pattern, content, re.DOTALL)
    if resources_match:
        files_section = resources_match.group(2)
        new_files = files_section
        for sound_file in sound_files:
            new_files += f"\n\t\t\t\t{build_uuids[sound_file]} /* {sound_file} in Resources */,"
        
        content = content.replace(resources_match.group(2), new_files)
    
    # Write the updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully added CAF files to Xcode project!")
    print("Added files:")
    for sound_file in sound_files:
        print(f"  - {sound_file} (FileRef: {file_uuids[sound_file]}, BuildFile: {build_uuids[sound_file]})")

if __name__ == "__main__":
    add_sounds_to_xcode()
