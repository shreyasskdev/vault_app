pub mod api;
mod frb_generated;
mod utils;

// android
#[cfg(target_os = "android")]
use jni::JavaVM;
#[cfg(target_os = "android")]
use once_cell::sync::OnceCell;

// This global variable will hold the pointer to the Android JVM
#[cfg(target_os = "android")]
pub(crate) static JAVA_VM: OnceCell<JavaVM> = OnceCell::new(); // Added pub(crate)

#[no_mangle]
#[allow(non_snake_case)]
#[cfg(target_os = "android")]
pub unsafe extern "system" fn JNI_OnLoad(
    vm: *mut jni::sys::JavaVM, // Use raw pointer here
    _reserved: *mut std::ffi::c_void,
) -> jni::sys::jint {
    // Wrap the raw pointer into the jni crate's JavaVM struct
    if let Ok(vm_wrapper) = jni::JavaVM::from_raw(vm) {
        let _ = JAVA_VM.set(vm_wrapper);
    }
    jni::sys::JNI_VERSION_1_6
}
