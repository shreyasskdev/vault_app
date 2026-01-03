package com.example.vault

// import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity;

class MainActivity: FlutterFragmentActivity()
{
    init {
        // "rust_lib_vault" must match the [lib] name in your Cargo.toml
        System.loadLibrary("rust_lib_vault") 
    }
}
