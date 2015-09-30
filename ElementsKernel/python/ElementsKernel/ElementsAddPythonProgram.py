##
# @file: ElementsKernel/ElementsAddPythonProgram.py
# @author: Nicolas Morisset
#          Astronomy Department of the University of Geneva
#
# @date: 01/07/15
#
# This script creates a new Elements python program
##

import argparse
import os
import time
import ElementsKernel.ElementsProjectCommonRoutines as epcr
import ElementsKernel.parseCmakeLists as pcl
import ElementsKernel.Logging as log

logger = log.getLogger('AddPythonProgram')

# Define constants
CMAKE_LISTS_FILE      = 'CMakeLists.txt'
PROGRAM_TEMPLATE_FILE = 'PythonProgram_template.py'

################################################################################

def createDirectories(module_dir, module_name):
    """
    Create directories needed for a python program
    """
    # Create the executable directory
    program_path = os.path.join(module_dir, 'python', module_name)
    epcr.makeDirectory(program_path)
    # Create the conf directory
    conf_dir = os.path.join(module_dir, 'conf', module_name)
    epcr.makeDirectory(conf_dir)
    
    # Create the scripts directory
    scripts_path = os.path.join(module_dir, 'scripts')
    epcr.makeDirectory(scripts_path)

################################################################################

def createFiles(module_dir, module_name, program_name):
    """
    Create files needed for a python program
    """
    # Create the executable directory
    init_file = os.path.join(module_dir, 'python', module_name, '__init__.py')
    conf_file = os.path.join(module_dir, 'conf', module_name, program_name +'.conf')
    if not os.path.exists(init_file):
        # Create an empty file
        f = open(init_file, 'w')
        f.close()
    if not os.path.exists(conf_file):
        f = open(conf_file, 'w')
        f.write('# Write your program options here. e.g. : option = string')
        f.close()

################################################################################

def substituteStringsInPythonProgramFile(file_path, program_name, module_name):
    """
    Substitute variables in the python template file and rename it
    """
    template_file = os.path.join(file_path, PROGRAM_TEMPLATE_FILE)
    # Substitute strings in h_template_file
    f = open(template_file, 'r')
    data = f.read()
    # Format all dependent projects
    # We put by default Elements dependency if no one is given
    date_str   = time.strftime("%x")
    author_str = epcr.getAuthor()
    # Make some substitutions
    file_name_str = os.path.join('python', module_name, program_name + '.py')
    new_data = data % {"FILE": file_name_str,
                       "DATE": date_str,
                       "AUTHOR": author_str,
                       "PROGRAMNAME": program_name}

    f.close()
    
    # Save new data
    file_name = template_file.replace(PROGRAM_TEMPLATE_FILE, program_name)
    file_name += '.py'
    f = open(file_name, 'w')
    f.write(new_data)
    f.close()
    os.remove(template_file)
        
################################################################################

def updateCmakeListsFile(module_dir, program_name):
    """
    Update the <CMakeList.txt> file
    """
    logger.info('# Updating the <%s> file' % CMAKE_LISTS_FILE)
    cmake_filename = os.path.join(module_dir, CMAKE_LISTS_FILE)

    # Backup the file
    epcr.makeACopy(cmake_filename)

    # Cmake file already exist
    if os.path.isfile(cmake_filename):
        f = open(cmake_filename, 'r')
        data = f.read()
        f.close()
        cmake_object = pcl.CMakeLists(data)
        module_name = cmake_object.elements_subdir_list[0].name + '.' + program_name

        # Add elements_install_conf_files if any        
        cmake_object.elements_install_python_modules = 'elements_install_python_modules()'
        cmake_object.elements_install_conf_files = 'elements_install_conf_files()'
        cmake_object.elements_install_scripts = 'elements_install_scripts()'
        
        program_object = pcl.ElementsAddPythonExecutable(program_name, module_name)
        cmake_object.elements_add_python_executable_list.append(program_object)              
                               
    # Write new data
    f = open(cmake_filename, 'w')
    f.write(str(cmake_object))
    f.close()

################################################################################

def createPythonProgram(current_dir, module_name, program_name):
    """
    Create the python program
    """
    logger.info('#')
    script_goes_on  = True
    createDirectories(current_dir, module_name)
    createFiles(current_dir, module_name, program_name)
    program_path = os.path.join(current_dir, 'python', module_name)
    script_goes_on = epcr.copyAuxFile(program_path, PROGRAM_TEMPLATE_FILE) 
    if script_goes_on:
        substituteStringsInPythonProgramFile(program_path, program_name,
                                            module_name)
        updateCmakeListsFile(current_dir, program_name)
    
    return script_goes_on

################################################################################

def defineSpecificProgramOptions():
    description = """
    This script creates an <Elements> python program at your current directory
    (default), this directory must be an <Elements> module.
           """
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('program_name', metavar='program-name', 
                        type=str, 
                        help='Program name')

    return parser

################################################################################

def mainMethod(args):

    logger.info('#')
    logger.info(
        '#  Logging from the mainMethod() of the ElementsAddPythonProgram script ')
    logger.info('#')

    try:
        script_goes_on  = True
        program_name    = args.program_name

        # Default is the current directory
        current_dir = os.getcwd()

        logger.info('# Current directory : %s', current_dir)

        # We absolutely need a Elements cmake file
        script_goes_on, module_name = epcr.isElementsModuleExist(current_dir)

        # Module as no version number, '1.0' is just for using the routine
        if script_goes_on:
            script_goes_on = epcr.isNameAndVersionValid(program_name, '1.0')
        
        program_file_path = os.path.join(current_dir, 'python', module_name, program_name+'.py')
        
        # Make sure the program does not already exist
        if script_goes_on:
            script_goes_on = epcr.isFileAlreadyExist(program_file_path, program_name) 
                  
        if script_goes_on:
            if os.path.exists(current_dir):
                if createPythonProgram(current_dir, module_name, program_name):
                    logger.info('# <%s> program successfully created in <%s>.' % 
                                (program_name, program_file_path))
                    # Remove backup file
                    epcr.deleteFile(os.path.join(current_dir, CMAKE_LISTS_FILE)+'~')
                    logger.info('# Script over.')
            else:
                logger.error('# <%s> project directory does not exist!' 
                             % current_dir)
        
        if not script_goes_on:
            logger.error('# Script aborted!')

    except Exception as e:
        logger.exception(e)
        logger.info('# Script stopped...')