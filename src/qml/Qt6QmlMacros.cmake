#
# Q6QmlMacros
#

#
# Create a Qml Module. Arguments:
#
# URI: Declares the module identifier of the module. The module identifier is
# the (dotted URI notation) identifier for the module, which must match the
# module's install path. (REQUIRED)
#
# VERSION: The module's version. (REQUIRED)
#
# TARGET_PATH: Overwrite the generated target path. By default the target path
#   is generated from the URI by replacing the '.' with a '/'. However, under
#   certain circumstance this may not be enough. Use this argument to provide
#   a replacement. (OPTIONAL)
#
# RESOURCE_PREFIX: Resource Prefix to be used when generating a static library.
#   When building a static library, the qmldir file is embedded into the library
#   using rcc. It is is also used by the Qt Quick Compiler to embed compiled
#   Qml files into a shared or static library. If none is supplied we will
#   generate the following prefix: /org.qt-project/imports/${target_path}.
#   (OPTIONAL)
#
# OUTPUT_DIRECTORY: If the module is not to be build under
#   ${CMAKE_CURRENT_BINARY_DIR}. This ensures the qmldir file is copied to the
#   right location.  (OPTIONAL)
#
# INSTALL_LOCATION: Intended installation directory for this module. If no
#   value is supplied, the default installation path will be ${INSTALL_QMLDIR}.
#   (OPTIONAL).
#
# DO_NOT_INSTALL_METADATA: When present, will not install the supporting files.
#
# INSTALL_QML_FILES: When present, will install the qml files along side the
#   plugin.
#
# SOURCES: List of C++ sources. (OPTIONAL)
#
# DEPENDENCIES: List of QML Module dependencies and their versions. The module
#   and its version must be separated via a slash(/). E.g. QtQuick/2.0
#
# QML_FILES: List of Qml files. See qt6_target_qml_files for more information
#   on how to specify additional properties on qml files. (OPTIONAL)
#
# CLASSNAME: Provides the class name of the C++ plugin used by the module. This
#   information is required for all the QML modules that depend on a C++ plugin
#   for additional functionality. Qt Quick applications built with static
#   linking cannot resolve the module imports without this information.
#   (REQUIRED for static targets)
#
# DESIGNER_SUPPORTED: Specify this argument if the plugin is supported by Qt
#   Quick Designer. By default, the plugin will not be supported. (OPTIONAL)
#
# TYPEINFO: Path to a file which declares a type description file for the module
#   that can be read by QML tools such as Qt Creator to access information about
#   the types defined by the module's plugins. (OPTIONAL)
#
# IMPORTS: List of other Qml Modules that this module imports. (OPTIONAL)
#
# RESOURCE_EXPORT: In static builds, when Qml files are processed via the Qt
#   Quick Compiler generate a separate static library that will be linked in
#   as an Interface. Supply an output variable to perform any custom actions
#   on these extra generated targets.
#
# SKIP_TYPE_REGISTRATION: When present will cause the generated qmldir file
#   to not list any qml types. These are expected to be registered by the
#   c++ plugin code instead.
#

function(qt6_add_qml_module target)

    set(args_optional
        GENERATE_QMLTYPES
        DESIGNER_SUPPORTED
        DO_NOT_INSTALL_METADATA
        SKIP_TYPE_REGISTRATION
        INSTALL_QML_FILES
    )

    if (QT_BUILDING_QT)
        list(APPEND args_optional DO_NOT_CREATE_TARGET)
    endif()

    set(args_single
        RESOURCE_PREFIX
        URI
        TARGET_PATH
        VERSION
        OUTPUT_DIRECTORY
        INSTALL_LOCATION
        CLASSNAME
        TYPEINFO
        RESOURCE_EXPORT
    )

    set(args_multi
       SOURCES
       QML_FILES
       IMPORTS
       DEPENDENCIES
    )

    cmake_parse_arguments(arg
       "${args_optional}"
       "${args_single}"
       "${args_multi}"
       ${ARGN}
    )

    if (NOT arg_URI)
        message(FATAL_ERROR "qt6_add_qml_module called without a module URI. Please specify one using the URI argument.")
    endif()

    if (NOT arg_VERSION)
        message(FATAL_ERROR "qt6_add_qml_module called without a module version. Please specify one using the VERSION argument.")
    endif()

    if (NOT "${arg_VERSION}" MATCHES "[0-9]+\\.[0-9]+")
        message(FATAL_ERROR "qt6_add_qml_module called with an invalid version argument: '${arg_VERSION}'. Expected version style: VersionMajor.VersionMinor.")
    endif()

    if (NOT BUILD_SHARED_LIBS AND NOT arg_CLASSNAME)
        message(FATAL_ERROR "qt6_add_qml_module Static builds of Qml modules require a class name, none was provided. Please specify one using the CLASSNAME argument.")
    endif()

    if (arg_DO_NOT_CREATE_TARGET AND NOT TARGET ${target})
        message(FATAL_ERROR "qt6_add_qml_module called with DO_NOT_CREATE_TARGET, but the given target '${target}' is not a cmake target")
    endif()

    if (arg_DO_NOT_CREATE_TARGET)
        get_target_property(target_type ${target} TYPE)
        if (target_type STREQUAL "STATIC_LIBRARY")
            set(is_static TRUE)
        elseif(target_type STREQUAL "MODULE_LIBRARY")
            set(is_static FALSE)
        else()
            message(FATAL_ERROR "qt6_add_qml_module called with DO_NOT_CREATE_TARGET, but target '${target}' is neither a static or a module library.")
        endif()
    else()
        if(NOT BUILD_SHARED_LIBS)
            add_library(${target} STATIC)
            set(is_static TRUE)
        else()
            add_library(${target} MODULE)
            set(is_static FALSE)
        endif()
    endif()

    if (NOT arg_TARGET_PATH)
        string(REPLACE "." "/" arg_TARGET_PATH ${arg_URI})
    endif()

    if (NOT arg_RESOURCE_PREFIX)
        set(arg_RESOURCE_PREFIX "/org.qt-project/imports")
    endif()

    if (NOT arg_INSTALL_LOCATION)
        set(arg_INSTALL_LOCATION "${INSTALL_QMLDIR}/${arg_TARGET_PATH}")
    endif()
    if (DEFINED QT_WILL_INSTALL AND NOT QT_WILL_INSTALL
            AND NOT IS_ABSOLUTE "${arg_INSTALL_LOCATION}")
        set(arg_INSTALL_LOCATION "${QT_BUILD_DIR}/${arg_INSTALL_LOCATION}")
    endif()

    set_target_properties(${target}
        PROPERTIES
            QT_QML_MODULE_TARGET_PATH ${arg_TARGET_PATH}
            QT_QML_MODULE_URI ${arg_URI}
            QT_RESOURCE_PREFIX ${arg_RESOURCE_PREFIX}/${arg_TARGET_PATH}
            QT_QML_MODULE_VERSION ${arg_VERSION}
            QT_QML_MODULE_INSTALL_DIR ${arg_INSTALL_LOCATION}
            QT_QML_MODULE_RESOURCE_EXPORT "${arg_RESOURCE_EXPORT}"
    )

    if (arg_OUTPUT_DIRECTORY AND NOT DO_NOT_CREATE_TARGET)
        set_target_properties(${target}
            PROPERTIES
                LIBRARY_OUTPUT_DIRECTORY ${arg_OUTPUT_DIRECTORY}
                ARCHIVE_OUTPUT_DIRECTORY ${arg_OUTPUT_DIRECTORY}
         )
    endif()
    if (arg_OUTPUT_DIRECTORY)
        set(target_output_dir ${arg_OUTPUT_DIRECTORY})
    else()
        if(is_static)
            get_target_property(target_output_dir ${target} ARCHIVE_OUTPUT_DIRECTORY)
        else()
            get_target_property(target_output_dir ${target} LIBRARY_OUTPUT_DIRECTORY)
        endif()
    endif()

    if (arg_INSTALL_QML_FILES)
        set_target_properties(${target} PROPERTIES QT_QML_MODULE_INSTALL_QML_FILES TRUE)
    endif()

    if (arg_SKIP_TYPE_REGISTRATION)
        set_target_properties(${target} PROPERTIES QT_QML_MODULE_SKIP_TYPE_REGISTRATION TRUE)
    endif()

    if (arg_SOURCES)
        target_sources(${target} PRIVATE ${arg_SOURCES})
    endif()

    # Tracker so we can generate unique resource names for multiple
    # target_qml_files() calls.
    set_target_properties(${target} PROPERTIES QT6_QML_MODULE_ADD_QML_FILES_COUNT 1)

    # Generate qmldir file
    set(qmldir_file "${CMAKE_CURRENT_BINARY_DIR}/qmldir")
    set_target_properties(${target} PROPERTIES QT_QML_MODULE_QMLDIR_FILE ${qmldir_file})
    set(qmldir_file_contents "module ${arg_URI}\n")
    string(APPEND qmldir_file_contents "plugin ${target}\n")
    if (arg_CLASSNAME)
        string(APPEND qmldir_file_contents "classname ${arg_CLASSNAME}\n")
    endif()
    if (arg_DESIGNER_SUPPORTED)
        string(APPEND qmldir_file_contents "designersupported\n")
    endif()
    if (arg_TYPEINFO)
        string(APPEND qmldir_file_contents "typeinfo ${arg_TYPEINFO}\n")
    else()
        # This always need to be written out since at the moment we have cases
        # where qmltyperegistrar is not run with the plugin but on a module
        # e.g: src/qml generates the qmltypes for src/imports/qtqml.
        # When this has been fixed/standardized we should move this to
        # qt6_qml_type_registration() so that it is written out when the
        # plugins.qmltypes is actually generated.
        string(APPEND qmldir_file_contents "typeinfo plugins.qmltypes\n")
    endif()
    foreach(import IN LISTS arg_IMPORTS)
        string(APPEND qmldir_file_contents "import ${import}\n")
    endforeach()

    foreach(dependency IN LISTS arg_DEPENDENCIES)
        string(FIND ${dependency} "/" slash_position REVERSE)
        if (slash_position EQUAL -1)
            message(FATAL_ERROR "Dependencies should follow the format 'ModuleName/VersionMajor.VersionMinor'")
        endif()
        string(SUBSTRING ${dependency} 0 ${slash_position} dep_module)
        math(EXPR slash_position "${slash_position} + 1")
        string(SUBSTRING ${dependency} ${slash_position} -1 dep_version)
        if (NOT dep_version MATCHES "[0-9]+\\.[0-9]+")
            message(FATAL_ERROR "Invalid module dependency version number. Expected VersionMajor.VersionMinor.")
        endif()
        string(APPEND qmldir_file_contents "depends ${dep_module} ${dep_version}\n")
    endforeach()

    file(WRITE ${qmldir_file} ${qmldir_file_contents})

    # Process qml files
    if (arg_QML_FILES)
        qt6_target_qml_files(${target} FILES ${arg_QML_FILES})
    endif()

    # Embed qmldir in static builds
    if (is_static)
        string(REPLACE "/" "_" qmldir_resource_name ${arg_TARGET_PATH})
        string(APPEND qmldir_resource_name "_qmldir")

        set_source_files_properties("${qmldir_file}"
            PROPERTIES QT_RESOURCE_ALIAS "qmldir"
        )

        set(resource_target "Foo")
        QT6_ADD_RESOURCES(${target} ${qmldir_resource_name}
            PREFIX ${target_resource_prefix}
            FILES "${qmldir_file}"
            OUTPUT_TARGETS resource_targets
        )

        if (resource_targets AND arg_RESOURCE_EXPORT)
            install(TARGETS ${resource_targets}
                EXPORT "${arg_RESOURCE_EXPORT}"
                DESTINATION ${arg_INSTALL_LOCATION}
            )
        endif()
    else()
        # Copy QMLDIR file to build directory
        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
                ${qmldir_file}
                ${target_output_dir}
        )

        # Install QMLDIR file
        if (NOT DO_NOT_INSTALL_METADATA)
            install(FILES ${qmldir_file}
                DESTINATION ${arg_INSTALL_LOCATION}
            )
        endif()
    endif()

    # Install and Copy plugin.qmltypes if exists
    set(target_plugin_qmltypes "${CMAKE_CURRENT_SOURCE_DIR}/plugins.qmltypes")
    if (EXISTS ${target_plugin_qmltypes})
        set_target_properties(${target}
            PROPERTIES QT_QML_MODULE_PLUGIN_TYPES_FILE "${target_plugin_qmltypes}"
        )
        file(APPEND ${qmldir_file} "typeinfo plugins.qmltypes\n")
        if (NOT arg_DO_NOT_INSTALL_METADATA)
            install(FILES ${target_plugin_qmltypes}
                DESTINATION ${arg_INSTALL_LOCATION}
            )
        endif()

        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
                ${target_plugin_qmltypes}
                ${target_output_dir}
        )
    endif()

    # Copy/Install type info file
    if (EXISTS ${arg_TYPEINFO})
        if (NOT arg_DO_NOT_INSTALL_METADATA)
            install(FILES ${arg_TYPEINFO}
                DESTINATION ${arg_INSTALL_LOCATION}
            )
        endif()

        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
                ${arg_TYPEINFO}
                ${target_output_dir}
        )
    endif()

    # Generate meta types data
    if (arg_GENERATE_QMLTYPES)
        qt6_qml_type_registration(${target})
    endif()
endfunction()


#
# Add Qml files (.qml,.js,.mjs) to a Qml module. This will also append the
# qml files to the qmldir file of the module. Two source file properties can
# be used to control the generated qmldir entry.
#
# QT_QML_SOURCE_VERSION: Version for this qml file. If not present the module
#   version will be used.
# QT_QML_SOURCE_TYPENAME: Override the file's type name. If not present the
#   type name will be deduced using the file's basename.
# QT_QML_SINGLETON_TYPE: Set to true if this qml file contains a singleton
#   type.
# QT_QML_INTERNAL_TYPE: When set to true, the type specified by
#   QT_QML_SOURCE_TYPENAME will not be available to users of this module.
# QT_QML_SKIP_QMLDIR_ENTRY: When set to true, no qmldir entry will be created for
#   the source file. Useful if a file needs to be installed (like a private JS
#   file) but does not expose a public type.
#
#   e.g.:
#       set_source_files_properties(my_qml_file.qml
#           PROPERTIES
#               QT_QML_SOURCE_VERSION 2.0
#               QT_QML_SOURCE_TYPENAME MyQmlFile
#
#       qt6_target_qml_files(my_qml_module
#           FILES
#               my_qml_file.qml
#       )
#
# Will produce the following entry in the qmldir file
#
#   MyQmlFile 2.0 my_qml_file.qml
#
#
function(qt6_target_qml_files target)

    cmake_parse_arguments(arg "" "" "FILES" ${ARGN})
    get_target_property(resource_count ${target} QT6_QML_MODULE_ADD_QML_FILES_COUNT)
    get_target_property(qmldir_file ${target} QT_QML_MODULE_QMLDIR_FILE)
    get_target_property(install_qml_files ${target} QT_QML_MODULE_INSTALL_QML_FILES)
    if (NOT qmldir_file)
        message(FATAL_ERROR "qt6_target_qml_file: ${target} is not a Qml module")
    endif()

    if (NOT arg_FILES)
        return()
    endif()
    math(EXPR new_count "${resource_count} + 1")
    set_target_properties(${target} PROPERTIES QT6_QML_MODULE_ADD_QML_FILES_COUNT ${new_count})

    qt6_add_resources(${target} "qml_files${new_count}"
        FILES ${arg_FILES}
        OUTPUT_TARGETS resource_targets
    )
    get_target_property(skip_type_registration ${target} QT_QML_MODULE_SKIP_TYPE_REGISTRATION)
    get_target_property(target_resource_export ${target} QT_QML_MODULE_RESOURCE_EXPORT)
    get_target_property(qml_module_install_dir ${target} QT_QML_MODULE_INSTALL_DIR)
    if (resource_targets)
        install(TARGETS ${resource_targets}
            EXPORT "${target_resource_export}"
            DESTINATION ${qm_module_install_dir}
        )
    endif()

    set(file_contents "")
    foreach(qml_file IN LISTS arg_FILES)
        if (install_qml_files)
            if (NOT QT_WILL_INSTALL)
                file(COPY "${qml_file}" DESTINATION "${qml_module_install_dir}")
            else()
                install(FILES "${qml_file}" DESTINATION "${qml_module_install_dir}")
            endif()
        endif()

        if (skip_type_registration AND qml_file MATCHES "\\.qml$")
            continue()
        endif()

        get_source_file_property(qml_file_skip_qmldir ${qml_file} QT_QML_SKIP_QMLDIR_ENTRY)
        if (qml_file_skip_qmldir)
            continue()
        endif()

        get_source_file_property(qml_file_version ${qml_file} QT_QML_SOURCE_VERSION)
        get_source_file_property(qml_file_typename ${qml_file} QT_QML_SOURCE_TYPENAME)
        get_source_file_property(qml_file_singleton ${qml_file} QT_QML_SINGLETON_TYPE)
        get_source_file_property(qml_file_internal ${qml_file} QT_QML_INTERNAL_TYPE)
        get_target_property(qml_module_version ${target} QT_QML_MODULE_VERSION)

        if (NOT qml_file_version)
            set(qml_file_version ${qml_module_version})
        endif()

        if (NOT qml_file_typename)
            get_filename_component(qml_file_typename ${qml_file} NAME_WLE)
        endif()

        if (qml_file_singleton)
            string(APPEND file_contents "[singleton] ")
        endif()

        string(APPEND file_contents "${qml_file_typename} ${qml_file_version} ${qml_file}\n")

        if (qml_file_internal)
            string(APPEND file_contents "internal ${qml_file_typename} ${qml_file}\n")
        endif()

    endforeach()
    file(APPEND ${qmldir_file} ${file_contents})
endfunction()

function(qt6_qml_type_registration target)

    get_target_property(import_name ${target} QT_QML_MODULE_URI)
    if (NOT import_name)
        message(FATAL_ERROR "Target ${target} is not a QML module")
    endif()

    cmake_parse_arguments(args "COPY_OVER_INSTALL" "INSTALL_DIR" "" ${ARGN})

    set(meta_types_args)
    if (QT_BUILDING_QT AND NOT QT_WILL_INSTALL)
        set(arg_COPY_OVER_INSTALL TRUE)
    endif()
    if (arg_INSTALL_DIR)
        list(APPEND meta_types_args INSTALL_DIR "${arg_INSTALL_DIR}")
    endif()
    if (arg_COPY_OVER_INSTALL)
        list(APPEND meta_types_args COPY_OVER_INSTALL)
    endif()

    qt6_generate_meta_types_json_file(${target} ${meta_types_args})

    get_target_property(import_version ${target} QT_QML_MODULE_VERSION)
    get_target_property(target_source_dir ${target} SOURCE_DIR)
    get_target_property(target_binary_dir ${target} BINARY_DIR)
    get_target_property(target_metatypes_file ${target} INTERFACE_QT_META_TYPES_BUILD_FILE)
    if (NOT target_metatypes_file)
        message(FATAL_ERROR "Target ${target} does not have a meta types file")
    endif()

    # Extract major and minor version
    if (NOT import_version MATCHES "[0-9]+\\.[0-9]+")
        message(FATAL_ERROR "Invalid module dependency version number. Expected VersionMajor.VersionMinor.")
    endif()
    #string(FIND "${import_version}" "." dot_location)
    #string(SUBSTRING ${import_version} 0 ${dot_location} major_version)
    #math(EXPR dot_location "${dot_location}+1")
    #string(SUBSTRING ${import_version} ${dot_location} -1 minor_version)
    string(REPLACE "." ";" import_version_split "${import_version}")
    list(LENGTH import_version_split import_version_split_length)
    if(import_version_split_length GREATER 0)
        list(GET import_version_split 0 major_version)
    endif()
    if(import_version_split_length GREATER 1)
        list(GET import_version_split 1 minor_version)
    endif()

    # check if plugins.qmltypes is already defined
    get_target_property(target_plugin_qmltypes ${target} QT_QML_MODULE_PLUGIN_TYPES_FILE)
    if (target_plugin_qmltypes)
        message(FATAL_ERROR "Target ${target} already has a plugins.qmltypes set.")
    endif()

    set(cmd_args)
    set(plugin_types_file ${target_binary_dir}/plugins.qmltypes)
    set_target_properties(${target} PROPERTIES
        QT_QML_MODULE_PLUGIN_TYPES_FILE ${plugin_types_file}
    )
    list(APPEND cmd_args
        --generate-qmltypes=${plugin_types_file}
        --import-name=${import_name}
        --major-version=${major_version}
        --minor-version=${minor_version}
    )

    # Run a script to recursively evaluate all the metatypes.json files in order
    # to collect all foreign types.
    string(TOLOWER "${target}_qmltyperegistrations.cpp" type_registration_cpp_file_name)
    set(foreign_types_file "${target_binary_dir}/qmltypes/foreign_types.txt")
    set(type_registration_cpp_file "${target_binary_dir}/${type_registration_cpp_file_name}")

    set(dependency_file_cpp "${target_binary_dir}/qmltypes/${type_registration_cpp_file_name}.d")
    file(RELATIVE_PATH cpp_file_name "${${CMAKE_PROJECT_NAME}_BINARY_DIR}" "${type_registration_cpp_file}")

    set (use_dep_files FALSE)
    if (CMAKE_GENERATOR STREQUAL "Ninja" OR CMAKE_GENERATOR STREQUAL "Ninja Multi-Config")
        set(use_dep_files TRUE)
    endif()

    # Enable evaluation of metatypes.json source interfaces
    set_target_properties(${target} PROPERTIES QT_CONSUMES_METATYPES TRUE)
    set(genex_list "$<REMOVE_DUPLICATES:$<FILTER:$<TARGET_PROPERTY:${target},SOURCES>,INCLUDE,metatypes.json$>>")
    set(genex_main "$<JOIN:${genex_list},$<COMMA>>")
    file(GENERATE OUTPUT "${foreign_types_file}"
        CONTENT "$<IF:$<BOOL:${genex_list}>,--foreign-types=${genex_main},\n>"
    )

    list(APPEND cmd_args
        "@${foreign_types_file}"
    )

    set(dependencies_json_file "${target_source_dir}/dependencies.json")
    if (EXISTS ${dependencies_json_file})
        list(APPEND cmd_args --dependencies=${dependencies_json_file})
    endif()

    if (TARGET ${target}Private)
        list(APPEND cmd_args --private-includes)
    endif()

    get_target_property(target_metatypes_json_file ${target} INTERFACE_QT_META_TYPES_BUILD_FILE)
    if (NOT target_metatypes_json_file)
        message(FATAL_ERROR "Need target metatypes.json file")
    endif()

    set(registration_cpp_file_dep_args)
    if (use_dep_files)
        set(registration_cpp_file_dep_args DEPFILE ${dependency_file_cpp})
        file(GENERATE OUTPUT "${dependency_file_cpp}"
            CONTENT "${cpp_file_name}: $<IF:$<BOOL:${genex_list}>,\\\n$<JOIN:${genex_list}, \\\n>, \\\n>"
        )
    endif()

    set(extra_env_command)
    if (WIN32)
        file(TO_NATIVE_PATH "${${PROJECT_NAME}_BINARY_DIR}/bin$<SEMICOLON>${CMAKE_INSTALL_PREFIX}/${INSTALL_BINDIR}$<SEMICOLON>%PATH%" env_path_native)
        set(extra_env_command COMMAND set PATH=${env_path_native})
    endif()
    add_custom_command(OUTPUT ${type_registration_cpp_file}
        DEPENDS
            ${foreign_types_file}
            ${target_metatypes_json_file}
            ${QT_CMAKE_EXPORT_NAMESPACE}::qmltyperegistrar
        ${extra_env_command}
        COMMAND
            $<TARGET_FILE:${QT_CMAKE_EXPORT_NAMESPACE}::qmltyperegistrar>
            ${cmd_args}
            -o ${type_registration_cpp_file}
            ${target_metatypes_json_file}
        ${registration_cpp_file_dep_args}
        COMMENT "Automatic QML type registration for target ${target}"
    )

    target_sources(${target} PRIVATE ${type_registration_cpp_file})
    set_source_files_properties(${type_registration_cpp_file} PROPERTIES
        SKIP_AUTOGEN ON
    )

    # Only install qml types if necessary
    get_target_property(install_qmltypes ${target} QT_QML_MODULE_INSTALL_QMLTYPES)
    if (install_qmltypes)
        get_target_property(qml_install_dir ${target} QT_QML_MODULE_INSTALL_DIR)
        if(NOT arg_COPY_OVER_INSTALL)
            install(FILES ${plugin_types_file} DESTINATION ${qml_install_dir})
        else()
            # For regular modules that have not been declared using
            # qt_add_qml_module (e.g: src/quick)
            if (DEFINED QT_WILL_INSTALL AND NOT QT_WILL_INSTALL
                    AND NOT IS_ABSOLUTE "${qml_install_dir}")
                set(qml_install_dir "${QT_BUILD_DIR}/${qml_install_dir}")
            endif()
            add_custom_command(TARGET ${target} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${plugin_types_file}"
                    "${qml_install_dir}/plugins.qmltypes"
                COMMENT "Copying ${plugin_types_file} to ${qml_install_dir}"
            )
        endif()
    endif()

    target_include_directories(${target} PRIVATE
        $<TARGET_PROPERTY:Qt::QmlPrivate,INTERFACE_INCLUDE_DIRECTORIES>
    )
endfunction()


# Enable the qt6_quick_compiler_process_resources function in qt6_add_resource()
set(QT6_ADD_RESOURCE_DECLARATIVE_EXTENSIONS TRUE)

# Inspect all files passed to a call to qt_add_resource. If there are any
# files present, invoke the quick compiler and return the remaining resource
# files that have not been processed in OUTPUT_REMAINING_RESOURCES as well as the new
# name for the resource in OUTPUT_RESOURCE_NAME.
function(qt6_quick_compiler_process_resources target resource_name)

    cmake_parse_arguments(arg
        "" "PREFIX;OUTPUT_REMAINING_RESOURCES;OUTPUT_RESOURCE_NAME;OUTPUT_GENERATED_TARGET" "FILES" ${ARGN}
    )

    set(qml_files)
    set(resource_files)
    # scan for qml files
    foreach(file IN LISTS arg_FILES)
        # check whether this resource should not be processed by the qt quick
        # compiler
        get_source_file_property(skip_compiler_check ${file} QT_SKIP_QUICKCOMPILER)
        if (skip_compiler_check)
            list(APPEND resource_files ${file})
            continue()
        endif()

        if (${file} MATCHES "\.js$"
                OR ${file} MATCHES "\.mjs$"
                OR ${file} MATCHES "\.qml$")
            list(APPEND qml_files ${file})
        endif()
        list(APPEND resource_files ${file})
    endforeach()
    if (NOT TARGET ${QT_CMAKE_EXPORT_NAMESPACE}::qmlcachegen AND qml_files)
        message(WARNING "QT6_PROCESS_RESOURCE: Qml files were detected but the qmlcachgen target is not defined. Consider adding QmlTools to your find_package command.")
    endif()

    if (TARGET ${QT_CMAKE_EXPORT_NAMESPACE}::qmlcachegen AND qml_files)
        # Enable qt quick compiler support
        set(qml_resource_file "${CMAKE_CURRENT_BINARY_DIR}/.rcc/${resource_name}.qrc")
        if (resource_files)
            set(chained_resource_name "${resource_name}_qmlcache")
        endif()

        foreach(file IN LISTS qml_files)
            get_filename_component(file_absolute ${file} ABSOLUTE)
            file(RELATIVE_PATH file_relative ${CMAKE_CURRENT_SOURCE_DIR} ${file_absolute})
            __qt_get_relative_resource_path_for_file(file_resource_path ${file})
            if (arg_PREFIX STREQUAL "/")
                # TO_CMAKE_PATH does not clean up cases such as //Foo
                set(file_resource_path "/${file_resource_path}")
            else()
                set(file_resource_path "${arg_PREFIX}/${file_resource_path}")
            endif()
            file(TO_CMAKE_PATH ${file_resource_path} file_resource_path)
            list(APPEND file_resource_paths ${file_resource_path})
            string(REGEX REPLACE "\.js$" "_js" compiled_file ${file_relative})
            string(REGEX REPLACE "\.mjs$" "_mjs" compiled_file ${compiled_file})
            string(REGEX REPLACE "\.qml$" "_qml" compiled_file ${compiled_file})
            string(REGEX REPLACE "[\$#\?]+" "_" compiled_file ${compiled_file})
            set(compiled_file "${CMAKE_CURRENT_BINARY_DIR}/.rcc/qmlcache/${resource_name}/${compiled_file}.cpp")
            get_filename_component(out_dir ${compiled_file} DIRECTORY)
            if(NOT EXISTS ${out_dir})
                file(MAKE_DIRECTORY ${out_dir})
            endif()
            add_custom_command(
                OUTPUT ${compiled_file}
                ${QT_TOOL_PATH_SETUP_COMMAND}
                COMMAND
                    ${QT_CMAKE_EXPORT_NAMESPACE}::qmlcachegen
                    --resource-path "${file_resource_path}"
                    -o "${compiled_file}"
                    "${file_absolute}"
                DEPENDS
                    $<TARGET_FILE:${QT_CMAKE_EXPORT_NAMESPACE}::qmlcachegen>
                    "${file_absolute}"
            )
            target_sources(${target} PRIVATE ${compiled_file})
        endforeach()

        set(qmlcache_loader_list "${CMAKE_CURRENT_BINARY_DIR}/.rcc/qmlcache/${resource_name}/qml_loader_file_list.rsp")
        file(GENERATE
            OUTPUT ${qmlcache_loader_list}
            CONTENT "$<JOIN:${file_resource_paths},\n>"
        )

        set(qmlcache_loader_file "${CMAKE_CURRENT_BINARY_DIR}/.rcc/qmlcache/${resource_name}/qmlcache_loader.cpp")
        set(resource_name_arg "${resource_name}.qrc")
        if (chained_resource_name)
            set(resource_name_arg "${resource_name_arg}=${chained_resource_name}")
        endif()

        add_custom_command(
            OUTPUT ${qmlcache_loader_file}
            ${QT_TOOL_PATH_SETUP_COMMAND}
            COMMAND
                ${QT_CMAKE_EXPORT_NAMESPACE}::qmlcachegen
                --resource-name "${resource_name_arg}"
                -o "${qmlcache_loader_file}"
                "@${qmlcache_loader_list}"
            DEPENDS
                $<TARGET_FILE:${QT_CMAKE_EXPORT_NAMESPACE}::qmlcachegen>
                "${qmlcache_loader_list}"
        )

        __qt_propagate_generated_resource(${target}
            ${resource_name}
            ${qmlcache_loader_file}
            output_target)

        set(${arg_OUTPUT_GENERATED_TARGET} "${output_target}" PARENT_SCOPE)

        if (resource_files)
            set(resource_name ${chained_resource_name})
        endif()

        # The generated qmlcache_loader source file uses private headers of Qml, so make sure
        # if the object library was created, it depends on the Qml target. If there's no target,
        # that means the target is a shared library and the sources are directly added to the target
        # via target_sources, so add dependency in that case as well.
        set(chosen_target "target") # shared library case
        if(output_target)
            set(chosen_target "output_target") # static library case.
        endif()
        target_link_libraries(${${chosen_target}} PRIVATE ${QT_CMAKE_EXPORT_NAMESPACE}::Qml)
    else()
        set(resource_files ${arg_FILES})
    endif()

    set(${arg_OUTPUT_REMAINING_RESOURCES} ${resource_files} PARENT_SCOPE)
    set(${arg_OUTPUT_RESOURCE_NAME} ${resource_name} PARENT_SCOPE)
endfunction()
