EXECUTABLE_NAME :: "main";
MAIN_FILE       :: "src/main.jai";
D3D12_MODULE    :: "d3d12-preview";

MODULE_DLLS :: string.[
    "dxcompiler-preview/lib/dxcompiler.dll",
    "dxcompiler-preview/lib/dxil.dll",
    "D3D12MA/windows/D3D12MA.dll",
    "WinPixRuntime/lib/WinPixEventRuntime.dll",
];

#run,stallable build();

build :: () {
    options := get_build_options();
    args := options.compile_time_command_line;

    import_path: [..] string;
    array_add(*import_path, "modules");
    array_add(*import_path, ..options.import_path);
    options.import_path = import_path;

    set_build_options_dc(.{do_output=false});
    set_working_directory(#filepath);

    build_dir := "build_debug";
    set_optimization(*options, .DEBUG);
    options.output_executable_name = EXECUTABLE_NAME;

    for arg: args {
        if arg == {
          case "release";
            build_dir = "build_release";
            set_optimization(*options, .OPTIMIZED);
          case "debug";
          case;
            compiler_report(tprint("Command-line argument #%, '%', is invalid. Valid options are: 'debug', 'release'.\n", it_index+1, arg));
        }
    }

    options.output_path = build_dir;
    make_directory_if_it_does_not_exist(build_dir);
    copy_runtime(build_dir, options.import_path);

    w := compiler_create_workspace(options.output_executable_name);
    set_build_options(options, w);
    add_build_file(MAIN_FILE, w);
}

copy_runtime :: (build_dir: string, import_path: [] string) {
    agility_sdk := "";
    for path: import_path {
        if file_exists(tprint("%/%/agility_sdk/D3D12Core.dll", path, D3D12_MODULE)) {
            agility_sdk = tprint("%/%/agility_sdk", path, D3D12_MODULE);
            break;
        }
    }
    if !agility_sdk {
        compiler_report(tprint("Could not find module '%' with the Agility SDK runtime.\n", D3D12_MODULE));
        return;
    }

    make_directory_if_it_does_not_exist(tprint("%/D3D12", build_dir));
    copy(tprint("%/D3D12Core.dll", agility_sdk),      tprint("%/D3D12/D3D12Core.dll", build_dir));
    copy(tprint("%/d3d12SDKLayers.dll", agility_sdk), tprint("%/D3D12/d3d12SDKLayers.dll", build_dir));

    for dll: MODULE_DLLS {
        for path: import_path {
            source := tprint("%/%", path, dll);
            if file_exists(source) {
                copy(source, tprint("%/%", build_dir, path_filename(source)));
                break;
            }
        }
    }
}

copy :: (source: string, dest: string) {
    if !copy_file(source, dest)  compiler_report(tprint("Could not copy '%' to '%'.\n", source, dest));
}

#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";
