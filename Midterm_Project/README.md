github 上有 2018 年的 ICLAB

看完覺得 omg

這個題目不是我大二下修 數位電路與系統 的 final project 嗎

這學期的 midterm project 難度怎麼高這麼多...

midterm project 花最多時間應該在了解 AMBA (Advanced Mirocontroller Bus Architecture)

也就是 DRAM 如何透過 AXI 4 Handshake Process 來與 design 溝通

設計須有 DRAM/SRAM(cache)/REG 三層架構

每個人設計的方法都不太一樣

我採用 submodule 的方式，把 DRAM/SRAM 包裝起來

input address 進去，output data 出來

top module 就不管 data 到底從 DRAM/SRAM 出來，只有計算相關的設計

ALU 部分直接爆開 (一堆乘法器...)
