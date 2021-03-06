(*
  Use:
  $ ocamlbuild -use-ocamlfind -package llvm fun_abs_phi.byte  
  We do not alloc space for local variables, we directly use the registers
 *)
 let define_abs llcontext llmodule = 
  let i32t = Llvm.i32_type llcontext in 
  let ttabs = Llvm.function_type i32t [| i32t |] in 
  let defabs = Llvm.define_function "abs" ttabs llmodule in 
  let ibuilder = Llvm.builder_at_end llcontext (Llvm.entry_block defabs) in 
  let param = Llvm.param defabs 0 in 
  let bthen = Llvm.append_block llcontext "then" defabs in 
  let belse = Llvm.append_block llcontext "else" defabs in 
  let bcont = Llvm.append_block llcontext "cont" defabs in 
  let zero = Llvm.const_int i32t 0 in   
  let icmp = Llvm.build_icmp Llvm.Icmp.Ult param zero "icmp" ibuilder in 
  let _ = Llvm.build_cond_br icmp bthen belse ibuilder in 
  Llvm.position_at_end bthen ibuilder;
  let neg = Llvm.build_sub zero param "neg" ibuilder in  
  let _ = Llvm.build_br bcont ibuilder in 
  Llvm.position_at_end belse ibuilder;
  let _ = Llvm.build_br bcont ibuilder in
  Llvm.position_at_end bcont ibuilder;
  let load = Llvm.build_phi [(neg, bthen) ; (param, belse)] "phi" ibuilder in
  let _ = Llvm.build_ret load ibuilder in 
  defabs

let _ = 
  let llvm_context = Llvm.global_context () in 
  let llmodule = Llvm.create_module llvm_context "fun-equals" in
  let _ = define_abs llvm_context llmodule in         
  Printf.printf "%s" (Llvm.string_of_llmodule llmodule);
  Llvm.dispose_module llmodule