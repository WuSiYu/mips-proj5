# 北工大-计算机组成原理课设

2020年7月，北京工业大学，大二下计算机组成原理，99/100分课设存档

 - 5级流水线MIPS-lite微系统，转发式流水线，当且仅当load-use冒险或控制冒险时插入一个流水线空泡
 - 包含CP0，仅实现外部中断功能
 - 按照学校课设要求，ALU加减法溢出后会向$30寄存器最低位写1
 - 4个简单外部设备：始终计数器，调试输入，调试输出，双功能定时器

地址空间：
 - RAM: 0x00000000 ~ 0x00002fff 12k
 - ROM: 0x00003000 ~ 0x00004fff 8k, PC起始地址0x00003000, 中断入口0x00004180
 - BUS: 0x00007800 ~ 0x00007fff device 0-7, 256 Byte pre device

设计框图：
![design.png](https://github.com/WuSiYu/mips-proj5/blob/master/design.png)

测试流程：
 1. 使用MARS编写或打开测试汇编程序（\*.asm)
 2. 使用MARS汇编并导出为Hexadecimal Text格式，存入`dump.txt`
 3. 运行dump2code.py，将`dump.txt`转换为Modelsim的格式，产生`code.txt`
 4. 将`code.txt`改为你喜欢的名字，并修改`test_microsystem.v`以指定该文件为引导代码或中断服务程序代码
 5. 在Modelsim中运行`test_microsystem.v`的仿真（选择不优化）

备注：
 - 实际上目前北工大计组课设大二下仅要求做朴素多周期CPU，并不要求流水线
 - 但本人比较无聊，就在多周期上改了个流水线玩玩
 - 部分实现和一些“标准设计”不同，又不是不能用
 - 不过我校的学弟们还是最好不要做课设时过度参考此项目（毕竟要学也得学点好的）
 - 由于是存档，不再接受pr，但issue和fork请随意

```
  // 5 Stage Pipeline MIPS-lite SoC
  // Designed by Wu23333 <wu.siyu@hotmail.com>, Date: 2020.07
  //
  // Supported instructions:
  //    addu, addiu, subu, sllv, srlv, and, andi, or, ori, xor, xori, nor, lui, slt, sltu, slti, sltiu,
  //    beq, bne, blez, bgtz, j, jal, jr, jalr,
  //    lb, lbu, lh, lhu, lw, sb, sh, sw, 
  //    mfc0, mtc0, eret
  //
  // Wire's naming conventions (most is):
  //    _*                           - Global connection
  //    _(EXE|MEM|WB)_forward        - Forward source
  //    (FETCH|DECODE|EXE|MEM|WB)_*  - Pipeline gate register output (eg. EXE_ALU_out is the output of E/M register, as one of MEM stage's input)
  //    other                        - Stage interconnection, usually defined near it's signal source module
  //
  // Programming NOTICE:
  //    0x00. Use MARS 4.5, Settings -> Memory Configuration:
  //                +-------------------------------------+
  //                |                                     |
  //                |  [ ]  Default                       |
  //                |  [#]  Compact, Data at Address 0    |
  //                |  [ ]  Compact, Text at Address 0    |
  //                |                                     |
  //                +-------------------------------------+
  //    0x01. To maintain compatibility with previous projects, NO DELAY SLOT, store PC + 4 when execute ins. like jal
  //    0x02. Always Kernel mode, CP0 only support Interrupt Exception
  //    0x03. One Pipeline bubble when: load->use data_hazard, control_hazard (jmp, branch, exception)
  //    0x04. if add, sub, addi overflow, result will not been saved and GPR $30[0] will set to 1
  //    0x05. Any bug, if you found, fix it or add it here (Although I think there is no bug)
  //


  /* 👇👇👇 WACKY DESIGN WARNING 👇👇👇 */
  // 以下代码包含惊险刺激的：
  //  0. 究极三目表达式套娃
  //  1. 长到带鱼屏都放不下的assign
  //  2. 上古老梗: 0xdeadbeef (Magic Number means "invalid")
  //  3. 塞满胶水逻辑的顶层模块
  //  4. 部分从课内大作业复用的祖传设计
  //  5. 后现代主义模块命名
  //  6. 套娃式DM / bus / CP0
  //  7. 我猜你能猜出来含义的模块参数顺序表示
  //  8. 由于上一条，像“企业级Java代码”一样长的变量名
  //  9. 直接用了一堆reg32拼来拼去的流水线闸门寄存器
  //  A. 由于ModelSim不支持UTF-8, 所以这段在ModelSim里全是乱码 
  //     (Because ModelSim does not support UTF-8, this paragraph is all garbled in ModelSim)
```

