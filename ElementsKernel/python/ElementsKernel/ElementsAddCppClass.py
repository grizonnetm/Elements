##
# @file: ElementsKernel/ElementsAddCppClass.py
# @author: Nicolas Morisset
#          Astronomy Department of the University of Geneva
#
# @date: 01/07/15
#
# This script will create a new Elements C++ Class
##

import argparse
import os
import re
import shutil
import time
import ElementsKernel.ElementsProjectCommonRoutines as epcr
import ElementsKernel.parseCmakeLists as pcl
import ElementsKernel.Logging as log

logger = log.getLogger('AddCppClass')

# Define constants
CMAKE_LISTS_FILE       = 'CMakeLists.txt'
H_TEMPLATE_FILE        = 'ClassName_template.h'
CPP_TEMPLATE_FILE      = 'ClassName_template.cpp'
UNITTEST_TEMPLATE_FILE = 'UnitTestFile_template.cpp'


################################################################################
    
def getClassName(str_subdir_class):
    """
    Get the class name and sub directory if any
    """
    name_list = str_subdir_class.split(os.path.sep)
    className = name_list[-1]
    subdir = str_subdir_class.replace(className,'')
    # Remove end slash
    subdir = subdir[:-1]
    logger.info('# Class name: %s' % className)
    if subdir:
        logger.info('# Sub directory: %s' % subdir)
    return subdir, className


################################################################################

def createDirectories(module_dir, module_name, subdir):
    """
    Create directories needed for a module
    """
    # Create Directories
    module_path = os.path.join(os.path.sep, module_dir, module_name, subdir)
    if not os.path.exists(module_path):
        os.makedirs(module_path)
    src_lib_path = os.path.join(os.path.sep, module_dir, 'src', 'lib', subdir)
    if not os.path.exists(src_lib_path):
        os.makedirs(src_lib_path)
    test_path = os.path.join(os.path.sep, module_dir, 'tests', 'src', subdir)
    if not os.path.exists(test_path):
        os.makedirs(test_path)

################################################################################
       
def substituteStringsInDotH(file_path, class_name, module_name, subdir):
    """
    Substitute variables in template file and rename the file
    """
    template_file = os.path.join(file_path, H_TEMPLATE_FILE)
    # Substitute strings in h_template_file
    f = open(template_file, 'r')
    data = f.read()
    # Format all dependent projects
    # We put by default Elements dependency if no one is given
    date_str = time.strftime("%x")
    author_str = epcr.getAuthor()
    # Make some substitutions
    file_name_str = os.path.join(module_name, subdir, class_name + '.h')
    define_words_str = '_' + file_name_str
    define_words_str = define_words_str.replace(H_TEMPLATE_FILE, class_name +'.h')
    define_words_str = define_words_str.replace('.','_')
    define_words_str = (define_words_str.replace(os.path.sep,'_')).upper()
    new_data = data % {"FILE": file_name_str,
                       "DATE": date_str,
                       "AUTHOR": author_str,
                       "OSSEP": os.sep,
                       "DEFINE_WORDS": define_words_str,
                       "SUBDIR": subdir,
                       "CLASSNAME": class_name,
                       "MODULENAME": module_name}

    f.close()
    # Save new data
    file_name = template_file.replace(H_TEMPLATE_FILE, class_name + '.h')
    f = open(file_name, 'w')
    f.write(new_data)
    f.close()
    os.remove(template_file)

################################################################################

def substituteStringsInDotCpp(file_path, class_name, module_name, subdir):
    """
    """
    template_file = os.path.join(file_path, CPP_TEMPLATE_FILE)
    
    # Substitute strings in template_file
    f = open(template_file, 'r')
    data = f.read()
    author_str = epcr.getAuthor()
    date_str   = time.strftime("%x")
    file_name_str = os.path.join('src', 'lib', subdir, class_name + '.cpp')
    new_data = data % {"FILE": file_name_str,
                       "DATE": date_str,
                       "AUTHOR": author_str,
                       "OSSEP": os.sep,
                       "MODULENAME": module_name,
                       "SUBDIR": subdir,
                       "CLASSNAME": class_name}

    f.close()
    # Save new data
    file_name = template_file.replace(CPP_TEMPLATE_FILE, class_name + '.cpp')
    f = open(file_name, 'w')
    f.write(new_data)
    f.close()
    os.remove(template_file)

################################################################################

def substituteStringsInUnitTestFile(file_path, class_name, module_name, subdir):
    """
    """
    template_file = os.path.join(file_path, UNITTEST_TEMPLATE_FILE)
    
    # Substitute strings in template_file
    f = open(template_file, 'r')
    data = f.read()
    author_str = epcr.getAuthor()
    date_str   = time.strftime("%x")
    file_name_str = os.path.join('tests','src',class_name + '_test.cpp')
    new_data = data % {"FILE": file_name_str,
                       "DATE": date_str,
                       "AUTHOR": author_str,
                       "OSSEP": os.sep,
                       "MODULENAME": module_name,
                       "SUBDIR": subdir,
                       "CLASSNAME": class_name}

    f.close()
    # Save new data
    file_name = template_file.replace(UNITTEST_TEMPLATE_FILE, class_name + '_test.cpp')
    f = open(file_name, 'w')
    f.write(new_data)
    f.close()
    os.remove(template_file)

################################################################################

def UpdateCmakeListsFile(module_dir, module_name, subdir, class_name,
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
                
        # Update elements_add_library macro
        if module_name:
            source = 'src' + os.sep + 'lib' + os.sep + subdir + '*.cpp'
            existing = [x for x in cmake_object.elements_add_library_list if x.name==module_name]
            link_libs = []
            if library_dep_list:
                 link_libs = link_libs + library_dep_list
            if module_dep_list:
                 link_libs = link_libs + module_dep_list
            if existing:
                if not source in existing[0].source_list:
                    existing[0].source_list.append(source)
                for lib in link_libs:
                    if not lib in existing[0].link_libraries_list:
                        existing[0].link_libraries_list.append(lib)
            else:
                source_list         = [source]
                include_dirs_list   = []
                public_headers_list = [module_name]
                lib_object = pcl.ElementsAddLibrary(module_name, source_list, 
                                                    link_libs, include_dirs_list,
                                                    public_headers_list)
                cmake_object.elements_add_library_list.append(lib_object)
            
            # Add unit test
            source_name = 'tests' + os.sep + subdir + class_name + '_test.cpp'
            unittest_object = pcl.ElementsAddUnitTest(class_name, [source_name], [module_name], [], 'Boost')
            cmake_object.elements_add_unit_test_list.append(unittest_object)
                   
    # Write new data
    f = open(cmake_filename, 'w')
    f.write(str(cmake_object))
    f.close()

################################################################################

def isClassFileAlreadyExist(class_name, module_dir, module_name, subdir):
    """
    Check if the class file does not already exist
    """
    script_goes_on = True
    module_path    = os.path.join(module_dir, module_name, subdir)
    file_name      = class_name + '.h'
    file_name_path = os.path.join(module_path, file_name)
    if os.path.exists(file_name_path):
        script_goes_on = False
        logger.error('# The <%s> class already exists! ' % class_name)
        logger.error('# The header file already exists: <%s>! ' % file_name_path)

    return script_goes_on
    

################################################################################
      
def createCppClass(module_dir, module_name, subdir, class_name, module_dep_list,
                    library_dep_list):
    """
    """
    
    script_goes_on = True 
    
    # Check the class does not exist already
    script_goes_on = isClassFileAlreadyExist(class_name, module_dir, module_name, 
                                          subdir)
    if script_goes_on:
        
        createDirectories(module_dir, module_name, subdir)                           
        class_h_path = os.path.join(os.path.sep, module_dir, module_name, subdir)
        epcr.copyAuxFile(class_h_path, H_TEMPLATE_FILE)    
        class_cpp_path = os.path.join(os.path.sep, module_dir,'src','lib', subdir)
        epcr.copyAuxFile(class_cpp_path, CPP_TEMPLATE_FILE)
        unittest_path = os.path.join(os.path.sep, module_dir,'tests','src', subdir)
        epcr.copyAuxFile(unittest_path, UNITTEST_TEMPLATE_FILE)
            
        UpdateCmakeListsFile(module_dir, module_name, subdir, class_name, 
                            module_dep_list, library_dep_list) 
         
        substituteStringsInDotH(class_h_path, class_name, module_name, subdir)  
        substituteStringsInDotCpp(class_cpp_path, class_name, module_name, subdir)  
        substituteStringsInUnitTestFile(unittest_path, class_name, module_name, subdir)
          
    return script_goes_on

################################################################################
    
def defineSpecificProgramOptions():
    description = """
           """
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('class_name', metavar='class-name', 
                        type=str, 
                        help='Module name')
    parser.add_argument('-md', '--module-dependency', metavar='module_name', 
                        action='append',type=str,
                        help='Dependency module name e.g. "-md ElementsKernel"')
    parser.add_argument('-ld', '--library-dependency', metavar='library_name',
                        action='append',type=str,
                        help='Dependency library name e.g. "-ld ElementsKernel"')

    return parser

################################################################################

def mainMethod(args):

    logger.info('#')
    logger.info('#  Logging from the mainMethod() of the ElementsAddCppClass \
    script ')
    logger.info('#')

    try:
        # True: no error occured
        script_goes_on       = True 
        
        module_list          = args.module_dependency
        library_list         = args.library_dependency
        (subdir,class_name) = getClassName(args.class_name)

        # Default is the current directory
        module_dir = os.getcwd()

        logger.info('# Current directory : %s', module_dir)

        # We absolutely need a Elements cmake file
        script_goes_on, module_name = epcr.isElementsModuleExist(module_dir)
        
        # Check aux files exist
        if script_goes_on:
            script_goes_on = epcr.isAuxFileExist(H_TEMPLATE_FILE)
        if script_goes_on:
            script_goes_on = epcr.isAuxFileExist(CPP_TEMPLATE_FILE)
        
        # Create CPP class    
        if script_goes_on:
            script_goes_on = createCppClass(module_dir, module_name, subdir,
                                        class_name, module_list, library_list)
            if script_goes_on:
                logger.info('# <%s> class successfully created in <%s>.' % 
                            (class_name, module_dir + os.sep + subdir))
                logger.info('# Script over.')
            else:
                logger.error('# Script aborted!')
        else:
            logger.error('# Script aborted!')

    except Exception as e:
        logger.exception(e)
        logger.info('# Script stopped...')