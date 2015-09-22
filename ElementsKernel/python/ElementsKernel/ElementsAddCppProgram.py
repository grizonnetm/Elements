##
# @file: ElementsKernel/ElementsAddCppProgram.py
# @author: Nicolas Morisset
#          Astronomy Department of the University of Geneva
#
# @date: 01/07/15
#
# This script will create a new Elements C++ Program
##

import argparse
import os
import re
import shutil
import time
import ElementsKernel.ElementsProjectCommonRoutines as epcr
import ElementsKernel.parseCmakeLists as pcl
import ElementsKernel.Logging as log

logger = log.getLogger('AddCppProgram')

# Define constants
CMAKE_LISTS_FILE      = 'CMakeLists.txt'
PROGRAM_TEMPLATE_FILE = 'program_template.cpp'

def createDirectories(module_dir, module_name):
    """
    Create directories needed for a program
    """
    # Create the executable directory
    program_path = os.path.join(module_dir, 'src', 'program')
    epcr.makeDirectory(program_path)
    # Create the conf directory
    conf_dir = os.path.join(module_dir, 'conf', module_name)
    epcr.makeDirectory(conf_dir)
    

################################################################################

def addConfFile(module_dir, module_name, program_name):
    """
    Create the configuration file by default
    """
    conf_file = os.path.join(module_dir, 'conf', module_name, program_name + '.conf')
    # check file does not exist
    if not os.path.exists(conf_file):
        f = open(conf_file, 'w')
        f.write('###############################################################################\n')
        f.write('#\n')
        f.write('# Configuration file for the <' + program_name + '> executable \n')
        f.write('#\n')
        f.write('###############################################################################\n')
        f.close()
    else:
        logger.warning('# The <%s> conf file has been kept as it already exists!'
                        % conf_file)
        logger.warning('# The <%s> conf file already exists! ' % conf_file)
        
        

         
################################################################################

def isProgramFileAlreadyExist(module_dir, program_name):
    """
    Check if the program file does not already exist
    """
    script_goes_on = True
    program_file_path = os.path.join(module_dir, 'src', 'program', program_name)
    program_file_path += '.cpp'
    if os.path.exists(program_file_path):
        script_goes_on = False
        logger.error('# The <%s> program already exists! ' % program_name)
        logger.error('# The file already exists: <%s>! ' % program_file_path)

    return script_goes_on

################################################################################
       
def substituteStringsInProgramFile(file_path, program_name, module_name):
    """
    Substitute variables in template file and rename the file
    """
    template_file = os.path.join(file_path, PROGRAM_TEMPLATE_FILE)
    # Substitute strings in h_template_file
    f = open(template_file, 'r')
    data = f.read()
    # Format all dependent projects
    # We put by default Elements dependency if no one is given
    date_str = time.strftime("%x")
    author_str = epcr.getAuthor()
    # Make some substitutions
    file_name_str = os.path.join('src', 'program', program_name + '.cpp')
    new_data = data % {"FILE": file_name_str,
                       "DATE": date_str,
                       "AUTHOR": author_str,
                       "PROGRAMNAME": program_name}

    f.close()
    # Save new data
    file_name = template_file.replace(PROGRAM_TEMPLATE_FILE, program_name)
    file_name += '.cpp'
    f = open(file_name, 'w')
    f.write(new_data)
    f.close()
    os.remove(template_file)

################################################################################

def updateCmakeListsFile(module_dir, module_name, program_name,
                         module_dep_list, library_dep_list):
    """
    """
    logger.info('# Updating the <%s> file' % CMAKE_LISTS_FILE)
    cmake_filename = os.path.join(os.path.sep, module_dir, CMAKE_LISTS_FILE)
    # Cmake file already exist
    if os.path.isfile(cmake_filename):
        f = open(cmake_filename, 'r')
        data = f.read()
        f.close()
        cmake_object = pcl.CMakeLists(data)
        module_name = cmake_object.elements_subdir_list[0].name
        
        # Update find_package macro
        if library_dep_list:
            for lib in library_dep_list:
                package_object = pcl.FindPackage(lib, [])
                cmake_object.find_package_list.append(package_object)
                
        # Update ElementsDependsOnSubdirs macro
        if module_dep_list:
            for mod_dep in module_dep_list:
                dep_object = pcl.ElementsDependsOnSubdirs([mod_dep])
                cmake_object.elements_depends_on_subdirs_list.append(dep_object)
                
        # Update elements_add_executable macro
        if program_name:
            source = 'src' + os.sep + 'lib' + os.sep + '*.cpp'
            existing = [x for x in cmake_object.elements_add_executable_list if x.name==program_name]
            existing_add_lib = [x for x in cmake_object.elements_add_library_list if x.name==module_name]
            link_libs = []
            if existing_add_lib:
                link_libs += [module_name]
            if library_dep_list:
                 link_libs = link_libs + library_dep_list
            if module_dep_list:
                 link_libs = link_libs + module_dep_list
            if existing:
                for lib in link_libs:
                    if not lib in existing[0].link_libraries_list:
                        existing[0].link_libraries_list.append(lib)
            else:
                exe_object = pcl.ElementsAddExecutable(program_name, source,
                                                       link_libs)
                cmake_object.elements_add_executable_list.append(exe_object)
                               
    # Write new data
    f = open(cmake_filename, 'w')
    f.write(str(cmake_object))
    f.close()

################################################################################
    
      
def createCppProgram(module_dir, module_name, program_name, module_dep_list,
                    library_dep_list):
    """
    Creates all necessary files for a program
    """    
    script_goes_on = True 
    script_goes_on = isProgramFileAlreadyExist(module_dir, program_name)
    if script_goes_on:
        createDirectories(module_dir, module_name)
        program_path = os.path.join(os.path.sep, module_dir,'src','program')
        epcr.copyAuxFile(program_path, PROGRAM_TEMPLATE_FILE)    
        substituteStringsInProgramFile(program_path, program_name, module_name)
        addConfFile(module_dir, module_name, program_name) 
        updateCmakeListsFile(module_dir, module_name, program_name,
                             module_dep_list, library_dep_list)             
    return script_goes_on

################################################################################
    
def defineSpecificProgramOptions():
    description = """
           """
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('program_name', metavar='program-name', 
                        type=str, 
                        help='Program name')
    parser.add_argument('-md', '--module-dependency', metavar='module_name',
                        action='append', type=str,
                        help='Dependency module name e.g."-md ElementsKernel"')
    parser.add_argument('-ld', '--library-dependency', metavar='library_name', 
                        action='append', type=str,
                        help='Dependency library name e.g."-ld ElementsKernel"')

    return parser

################################################################################

def mainMethod(args):

    logger.info('#')
    logger.info('#  Logging from the mainMethod() of the ElementsAddCppProgram script')
    logger.info('#')

    try:
        # True: no error occured
        script_goes_on       = True 
        
        program_name = args.program_name
        module_list  = args.module_dependency
        library_list = args.library_dependency

        # Default is the current directory
        current_dir = os.getcwd()

        logger.info('# Current directory : %s', current_dir)

        # We absolutely need a Elements cmake file
        script_goes_on, module_name = epcr.isElementsModuleExist(current_dir)
        
        if script_goes_on:
            script_goes_on = isProgramFileAlreadyExist(current_dir, program_name)   
                 
         # Check aux files exist
        if script_goes_on:
            script_goes_on = epcr.isAuxFileExist(PROGRAM_TEMPLATE_FILE)
       
        # Check aux files exist
        if script_goes_on:
            script_goes_on = epcr.isAuxFileExist(PROGRAM_TEMPLATE_FILE)
            
        if script_goes_on:
            # Create CPP program    
            script_goes_on = createCppProgram(current_dir, module_name, program_name,
                                        module_list, library_list)
            if script_goes_on:
                logger.info('# <%s> program successfully created in <%s>.' % 
                            (program_name, current_dir + os.sep + 'src'+ os.sep + 'program'))
                logger.info('# Script over.')
            else:
                logger.error('# Script aborted!')
        else:
            logger.error('# Script aborted!')

    except Exception as e:
        logger.exception(e)
        logger.info('# Script stopped...')