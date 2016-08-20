; Title: HP-41 Entry Points
; Time stamp: Tue Jan  7 13:49:07 1986
; Number of globals: 757

            .public ABS, ABTS10, ABTSEQ, ACOS, AD1_10, AD2_10, AD2_13, ADD1, ADD2
            .public ADDONE, ADRFCH, ADVNCE, AFORMT, AGTO, AJ2, AJ3, ALCL00, ALLOK
            .public ALPDEF, ANNOUT, ANN_14, AOFF, AON, AOUT15, APHST_, APND10
            .public APNDDG, APNDNW, APND_, APPEND, ARCL, ARGOUT, ASCLCA, ASCLCD, ASHF
            .public ASIN, ASN, ASN15, ASN20, ASRCH, ASTO, ATAN, AVAIL, AVAILA, AVIEW
            .public AXEQ, BAKAPH, BAKDE, BCDBIN, BEEP, BIGBRC, BKROM2, BLANK, BLINK
            .public BLINK1, BRT100, BRT140, BRT160, BRT200, BRT290, BRTS10, BST, BSTCAT
            .public BSTE, BSTE2, BSTEP, BSTEPA, CALDSP, CAT, CAT1, CAT2, CAT3, CF, CHKAD4
            .public CHKADR, CHKFUL, CHKRPC, CHK_NO_S, CHK_NO_S1, CHK_NO_S2, CHRLCD, CHS
            .public CHSA, CHSA1, CLA, CLCTMG, CLDSP, CLLCDE, CLP, CLR, CLREG, CLRLCD
            .public CLRPGM, CLRREG, CLRSB2, CLRSB3, CLSIG, CLST, CLX, CNTLOP, COLDST
            .public COPY, COS, CPGM10, CPGMHD, DAT106, DAT231, DAT260, DAT280, DAT300
            .public DAT320, DAT400, DAT500, DATENT, DATOFF, DCPL00, DCPLRT, DCRT10, DEC
            .public DECAD, DECADA, DECMPL, DEEXP, DEG, DEGDO, DEL, DELETE, DELLIN
            .public DELNNN, DEROVF, DEROW, DERUN, DERW00, DF060, DF150, DF160, DF200
            .public DFILLF, DFKBCK, DFRST8, DFRST9, DGENS8, DIGENT, DIGST_, DIV110
            .public DIV120, DIV15, DIVIDE, DOSKP, DOSRC1, DOSRCH, DROPST, DROWSY
            .public DRSY05, DRSY25, DRSY50, DRSY51, DSE, DSPCA, DSPCRG, DSPLN_, DSWKUP
            .public DTOR, DV1_10, DV2_10, DV2_13, D_R, ENCP00, END, END2, END3, ENG
            .public ENLCD, ENTER, ERR0, ERR110, ERR120, ERRAD, ERRDE, ERRIGN, ERRNE
            .public ERROF, ERROR, ERRPR, ERRRAM, ERRSUB, ERRTA, EXP10, EXP13, EXP400
            .public EXP500, EXP710, EXP720, EXSCR, E_TO_X, E_TO_X_MINUS_1, FACT, FC
            .public FCNTBL, FC_C, FDIG20, FDIGIT, FILLXL, FIND_NO_1, FIX, FIX57, FIXEND
            .public FLGANN, FLINK, FLINKA, FLINKM, FLINKP, FNDEND, FORMAT, FRAC, FS
            .public FSTIN, FS_C, GCP112, GCPK04, GCPK05, GCPKC, GCPKC0, GENLNK, GENNUM
            .public GETLIN, GETN, GETPC, GETPCA, GETX, GETXSQ, GETXY, GETY, GETYSQ
            .public GOL0, GOL1, GOL2, GOL3, GOLNGH, GOLONG, GOSUB, GOSUB0, GOSUB1
            .public GOSUB2, GOSUB3, GOSUBH, GOTINT, GRAD, GSB000, GSB256, GSB512
            .public GSB768, GSUBS1, GT3DBT, GTACOD, GTAI40, GTAINC, GTBYT, GTBYTA
            .public GTBYTO, GTCNTR, GTFEN1, GTFEND, GTLINK, GTLNKA, GTO, GTOL, GTONN
            .public GTO_5, GTRMAD, GTSRCH, HMSDV, HMSMP, HMS_H, HMS_MINUS, HMS_PLUS
            .public H_HMS, IN3B, INBCHS, INBYT, INBYT0, INBYT1, INBYTC, INBYTJ, INBYTP
            .public INCAD, INCAD2, INCADA, INCADP, INCGT2, IND, IND21, INEX, INLIN
            .public INLIN2, INPTDG, INSHRT, INSLIN, INSSUB, INSTR, INT, INTARG, INTFRC
            .public INTINT, INTXC, IORUN, ISG, KEYOP, KYOPCK, LASTX, LBL, LD90, LDDP10
            .public LDD_P_, LDSST0, LEFTJ, LINN1A, LINNM1, LINNUM, LN, LN10, LN1_PLUS_X
            .public LN560, LNAP, LNC10, LNC10_, LNC20, LNSUB, LNSUB_MINUS, LOAD3, LOG
            .public LSWKUP, MASK, MEAN, MEMCHK, MEMLFT, MESSL, MIDDIG, MINUS, MOD, MOD10
            .public MODE, MODE1, MOVREG, MP1_10, MP2_10, MP2_13, MPY150, MSG, MSG105
            .public MSG110, MSGA, MSGAD, MSGDE, MSGDLY, MSGE, MSGML, MSGNE, MSGNL
            .public MSGNO, MSGOF, MSGPR, MSGRAM, MSGROM, MSGTA, MSGWR, MSGX, MSGYES
            .public MULTIPLY, NAM40, NAM44_, NAME20, NAME21, NAME33, NAME37, NAME4A
            .public NAME4D, NAMEA, NBYTA0, NBYTAB, NEXT, NEXT1, NEXT2, NEXT3, NFRC
            .public NFRENT, NFRFST, NFRKB, NFRKB1, NFRNC, NFRNIO, NFRPR, NFRPU, NFRSIG
            .public NFRST_PLUS, NFRX, NFRXY, NLT000, NLT020, NLT040, NM44_5, NOPRT
            .public NOREG9, NOSKP, NOTFIX, NRM10, NRM11, NRM12, NRM13, NROOM3, NULTST
            .public NULT_, NULT_3, NULT_5, NWGOOS, NXBYT3, NXBYTA, NXBYTO, NXL1B, NXL3B2
            .public NXLCHN, NXLDEL, NXLIN, NXLIN3, NXLINA, NXLSST, NXLTX, NXTBYT, OCT
            .public OFF, OFFSHF, OFSHFT, ONE_BY_X, ONE_BY_X10, ONE_BY_X13, OPROMT
            .public OUTLCD, OUTROM, OVFL10, P10RTN, P6RTN, PACH10, PACH11, PACH12, PACH4
            .public PACK, PACKE, PACKN, PAK200, PAKEND, PAKSPC, PAR111, PAR112, PARA06
            .public PARA60, PARA61, PARA75, PARB40, PARS05, PARS56, PARS75, PARSDE
            .public PARSE, PARSEB, PATCH1, PATCH2, PATCH3, PATCH5, PATCH6, PATCH9
            .public PCKDUR, PCT, PCTCH, PGMAON, PI, PI_BY_2, PKIOAS, PLUS, PMUL
            .public POWER_OF_TEN, PR10RT, PR14RT, PR15RT, PR3RT, PROMF1, PROMF2
            .public PROMFC, PROMPT, PSE, PSESTP, PTBYTA, PTBYTM, PTBYTP, PTLINK
            .public PTLNKA, PTLNKB, PUTPC, PUTPCA, PUTPCD, PUTPCF, PUTPCL, PUTPCX
            .public PUTREG, P_R, QUTCAT, RAD, RAK06, RAK60, RAK70, RCL, RCSCR, RCSCR_
            .public RDN, RDNSUB, REGLFT, RFDS55, RG9LCD, RMCK05, RMCK10, RMCK15, RND
            .public ROLBAK, ROLLUP, ROMCHK, ROMH05, ROMH35, ROMHED, ROUND, ROW0, ROW10
            .public ROW11, ROW12, ROW120, ROW933, ROW940, RST05, RSTANN, RSTKB, RSTMS0
            .public RSTMS1, RSTMSC, RSTSEQ, RSTSQ, RSTST, RTJLBL, RTN, RTN30, RTOD
            .public RUN, RUNING, RUNNK, RUN_STOP, RW0110, RW0141, R_D, R_P, R_SCAT
            .public R_SUB, SARO21, SARO22, SAROM, SAVR10, SAVRC, SAVRTN, SCI, SCROL0
            .public SCROLL, SD, SEARC1, SEARCH, SEPXY, SERR, SETQ_P, SETSST, SF
            .public SGTO19, SHF10, SHF40, SHIFT, SIGMA, SIGMA_MINUS, SIGMA_PLUS
            .public SIGN, SIGREG, SIN, SINFR, SINFRA, SIZE, SIZSUB, SKP, SKPDEL
            .public SKPLIN, SNR10, SNR12, SNROM, SQR10, SQR13, SQRT, SRBMAP, SST
            .public SSTBST, SSTCAT, STATCK, STAYON, STBT10, STBT30, STBT31, STDEV
            .public STFLGS, STK, STK00, STK04, STMSGF, STO, STOLCC, STOP, STOPS
            .public STOPSB, STORFC, STOST0, STO_DIVIDE, STO_MINUS, STO_MULTIPLY
            .public STO_PLUS, STSCR, STSCR_, SUBONE, SUMCHK, SUMCK2, TAN, TBITMA
            .public TBITMP, TEN_TO_X, TEXT, TGSHF1, TODEC, TOGSHF, TONE, TONE7, TONE7X
            .public TONEB, TONSTF, TOOCT, TOPOL, TOREC, TRC10, TRC30, TRCS10, TRG100
            .public TRG240, TRG430, TRGSET, TSTMAP, TXRW10, TXTLB1, TXTLBL, TXTROM
            .public TXTROW, TXTSTR, UPLINK, VIEW, WKUP10, WKUP21, WKUP25, WKUP70
            .public WKUP80, XARCL, XASHF, XASN, XASTO, XAVIEW, XBAR, XBAR_, XBEEP
            .public XBST, XCAT, XCF, XCLSIG, XCLX1, XCOPY, XCUTB1, XCUTE, XCUTEB
            .public XDEG, XDELET, XDSE, XECROM, XEND, XEQ, XEQC01, XFS, XFT100, XGA00
            .public XGI, XGI07, XGI57, XGNN10, XGNN12, XGNN40, XGOIND, XGRAD, XGTO
            .public XISG, XLN1_PLUS_X, XMSGPR, XNNROW, XPACK, XPRMPT, XRAD, XRDN
            .public XRND, XROLLUP, XROM, XROMNF, XROW1, XRS45, XRTN, XR_S, XSCI, XSF
            .public XSGREG, XSIGN, XSIZE, XSST, XSTYON, XTOHRS, XTONE, XVIEW, XXEQ
            .public XX_EQ_0, XX_EQ_Y, XX_GT_0, XX_GT_Y, XX_LE_0, XX_LE_0A, XX_LE_Y
            .public XX_LT_0, XX_LT_Y, XX_NE_0, XX_NE_Y, XY_TO_X, X_BY_Y13, X_EQ_0
            .public X_EQ_Y, X_GT_0, X_GT_Y, X_LE_0, X_LE_Y, X_LT_0, X_LT_Y, X_NE_0
            .public X_NE_Y, X_TO_2, X_XCHNG, X_XCHNG_Y, Y_MINUS_X, Y_TO_X

ABS          .equlab 0x1076
ABTS10       .equlab 0xD16
ABTSEQ       .equlab 0xD12
ACOS         .equlab 0x107D
AD1_10       .equlab 0x1809
AD2_10       .equlab 0x1807
AD2_13       .equlab 0x180C
ADD1         .equlab 0x1CE0
ADD2         .equlab 0x1CE3
ADDONE       .equlab 0x1800
ADRFCH       .equlab 0x4
ADVNCE       .equlab 0x114D
AFORMT       .equlab 0x628
AGTO         .equlab 0x1085
AJ2          .equlab 0xDD4
AJ3          .equlab 0xDD0
ALCL00       .equlab 0x6C9
ALLOK        .equlab 0x2CD
ALPDEF       .equlab 0x3AE
ANNOUT       .equlab 0x75C
ANN_14       .equlab 0x75B
AOFF         .equlab 0x1345
AON          .equlab 0x133C
AOUT15       .equlab 0x2C2B
APHST_       .equlab 0x2E62
APND10       .equlab 0x1FF5
APNDDG       .equlab 0x1FFA
APNDNW       .equlab 0x2D14
APND_        .equlab 0x1FF3
APPEND       .equlab 0x2D0E
ARCL         .equlab 0x108C
ARGOUT       .equlab 0x2C10
ASCLCA       .equlab 0x2C5E
ASCLCD       .equlab 0x2C5D
ASHF         .equlab 0x1092
ASIN         .equlab 0x1098
ASN          .equlab 0x109E
ASN15        .equlab 0x27C2
ASN20        .equlab 0x27CC
ASRCH        .equlab 0x26C5
ASTO         .equlab 0x10A4
ATAN         .equlab 0x10AA
AVAIL        .equlab 0x28C4
AVAILA       .equlab 0x28C7
AVIEW        .equlab 0x10B2
AXEQ         .equlab 0x10B5
BAKAPH       .equlab 0x9E3
BAKDE        .equlab 0x9A5
BCDBIN       .equlab 0x2E3
BEEP         .equlab 0x10BB
BIGBRC       .equlab 0x4F
BKROM2       .equlab 0x2A91
BLANK        .equlab 0x5B7
BLINK        .equlab 0x899
BLINK1       .equlab 0x899
BRT100       .equlab 0x1D80
BRT140       .equlab 0x1DEC
BRT160       .equlab 0x1DA8
BRT200       .equlab 0x1E0F
BRT290       .equlab 0x1DAC
BRTS10       .equlab 0x1D6B
BST          .equlab 0x10C2
BSTCAT       .equlab 0xBBA
BSTE         .equlab 0x290B
BSTE2        .equlab 0x2AF2
BSTEP        .equlab 0x28DE
BSTEPA       .equlab 0x28EB
CALDSP       .equlab 0x29C3
CAT          .equlab 0x10C8
CAT1         .equlab 0xBC3
CAT2         .equlab 0xB53
CAT3         .equlab 0x1383
CF           .equlab 0x10CC
CHKAD4       .equlab 0x1686
CHKADR       .equlab 0x166E
CHKFUL       .equlab 0x5BA
CHKRPC       .equlab 0x222
CHK_NO_S     .equlab 0x14D8
CHK_NO_S1    .equlab 0x14D4
CHK_NO_S2    .equlab 0x14D9
CHRLCD       .equlab 0x5B9
CHS          .equlab 0x123A
CHSA         .equlab 0x1CDA
CHSA1        .equlab 0x1CDC
CLA          .equlab 0x10D1
CLCTMG       .equlab 0x3C9
CLDSP        .equlab 0x10E0
CLLCDE       .equlab 0x2CF0
CLP          .equlab 0x10E7
CLR          .equlab 0x1733
CLREG        .equlab 0x10ED
CLRLCD       .equlab 0x2CF6
CLRPGM       .equlab 0x228C
CLRREG       .equlab 0x2155
CLRSB2       .equlab 0xC00
CLRSB3       .equlab 0xC02
CLSIG        .equlab 0x10F3
CLST         .equlab 0x10F9
CLX          .equlab 0x1101
CNTLOP       .equlab 0xB9D
COLDST       .equlab 0x232
COPY         .equlab 0x1109
COS          .equlab 0x127C
CPGM10       .equlab 0x67F
CPGMHD       .equlab 0x67B
DAT106       .equlab 0x2D4C
DAT231       .equlab 0x2D77
DAT260       .equlab 0x2D94
DAT280       .equlab 0x2D98
DAT300       .equlab 0x2D9B
DAT320       .equlab 0x2DA2
DAT400       .equlab 0x2E05
DAT500       .equlab 0x2E10
DATENT       .equlab 0x2D2C
DATOFF       .equlab 0x390
DCPL00       .equlab 0x2EC3
DCPLRT       .equlab 0x2F0B
DCRT10       .equlab 0x2F0D
DEC          .equlab 0x132B
DECAD        .equlab 0x29C7
DECADA       .equlab 0x29CA
DECMPL       .equlab 0x2EC2
DEEXP        .equlab 0x88C
DEG          .equlab 0x1114
DEGDO        .equlab 0x172A
DEL          .equlab 0x1124
DELETE       .equlab 0x1127
DELLIN       .equlab 0x2306
DELNNN       .equlab 0x22A8
DEROVF       .equlab 0x8EB
DEROW        .equlab 0x4AD
DERUN        .equlab 0x8AD
DERW00       .equlab 0x4B2
DF060        .equlab 0x587
DF150        .equlab 0x482
DF160        .equlab 0x485
DF200        .equlab 0x4E7
DFILLF       .equlab 0x563
DFKBCK       .equlab 0x559
DFRST8       .equlab 0x562
DFRST9       .equlab 0x561
DGENS8       .equlab 0x836
DIGENT       .equlab 0x837
DIGST_       .equlab 0x8B2
DIV110       .equlab 0x18A5
DIV120       .equlab 0x18AF
DIV15        .equlab 0x18A9
DIVIDE       .equlab 0x106F
DOSKP        .equlab 0x1631
DOSRC1       .equlab 0x24E3
DOSRCH       .equlab 0x24E4
DROPST       .equlab 0xE4
DROWSY       .equlab 0x160
DRSY05       .equlab 0x161
DRSY25       .equlab 0x173
DRSY50       .equlab 0x190
DRSY51       .equlab 0x194
DSE          .equlab 0x112D
DSPCA        .equlab 0xB35
DSPCRG       .equlab 0xB26
DSPLN_       .equlab 0xFC7
DSWKUP       .equlab 0x1AD
DTOR         .equlab 0x1981
DV1_10       .equlab 0x189A
DV2_10       .equlab 0x1898
DV2_13       .equlab 0x189D
D_R          .equlab 0x110E
ENCP00       .equlab 0x952
END          .equlab 0x1132
END2         .equlab 0x3B6
END3         .equlab 0x3BE
ENG          .equlab 0x1135
ENLCD        .equlab 0x7F6
ENTER        .equlab 0x113E
ERR0         .equlab 0x18C3
ERR110       .equlab 0x22FB
ERR120       .equlab 0x22FF
ERRAD        .equlab 0x14E2
ERRDE        .equlab 0x282D
ERRIGN       .equlab 0xBB
ERRNE        .equlab 0x2E0
ERROF        .equlab 0xA2
ERROR        .equlab 0x22F5
ERRPR        .equlab 0x2184
ERRRAM       .equlab 0x2172
ERRSUB       .equlab 0x22E8
ERRTA        .equlab 0x2F17
EXP10        .equlab 0x1A0A
EXP13        .equlab 0x1A0D
EXP400       .equlab 0x1A21
EXP500       .equlab 0x1A61
EXP710       .equlab 0x1A4C
EXP720       .equlab 0x1A50
EXSCR        .equlab 0x192A
E_TO_X       .equlab 0x1147
E_TO_X_MINUS_1 .equlab 0x1163
FACT         .equlab 0x1154
FC           .equlab 0x115A
FCNTBL       .equlab 0x1400
FC_C         .equlab 0x116B
FDIG20       .equlab 0xE3D
FDIGIT       .equlab 0xE2F
FILLXL       .equlab 0xEA
FIND_NO_1    .equlab 0x1775
FIX          .equlab 0x1171
FIX57        .equlab 0xAC3
FIXEND       .equlab 0x2918
FLGANN       .equlab 0x1651
FLINK        .equlab 0x2928
FLINKA       .equlab 0x2927
FLINKM       .equlab 0x2929
FLINKP       .equlab 0x2925
FNDEND       .equlab 0x1730
FORMAT       .equlab 0xA7B
FRAC         .equlab 0x117C
FS           .equlab 0x1182
FSTIN        .equlab 0x14C2
FS_C         .equlab 0x1188
GCP112       .equlab 0x2BB5
GCPK04       .equlab 0x2BBC
GCPK05       .equlab 0x2BBE
GCPKC        .equlab 0x2B80
GCPKC0       .equlab 0x2B89
GENLNK       .equlab 0x239A
GENNUM       .equlab 0x5E8
GETLIN       .equlab 0x1419
GETN         .equlab 0x1CEA
GETPC        .equlab 0x2950
GETPCA       .equlab 0x2952
GETX         .equlab 0x1CEF
GETXSQ       .equlab 0x1CEE
GETXY        .equlab 0x1CEB
GETY         .equlab 0x1CED
GETYSQ       .equlab 0x1CEC
GOL0         .equlab 0x23D0
GOL1         .equlab 0x23D9
GOL2         .equlab 0x23E2
GOL3         .equlab 0x23EB
GOLNGH       .equlab 0xFD9
GOLONG       .equlab 0xFDA
GOSUB        .equlab 0xFDE
GOSUB0       .equlab 0x23D2
GOSUB1       .equlab 0x23DB
GOSUB2       .equlab 0x23E4
GOSUB3       .equlab 0x23ED
GOSUBH       .equlab 0xFDD
GOTINT       .equlab 0x2F8
GRAD         .equlab 0x111A
GSB000       .equlab 0x23FA
GSB256       .equlab 0x23FA
GSB512       .equlab 0x23FA
GSB768       .equlab 0x23FA
GSUBS1       .equlab 0x23C9
GT3DBT       .equlab 0xFEB
GTACOD       .equlab 0x1FDB
GTAI40       .equlab 0x341
GTAINC       .equlab 0x304
GTBYT        .equlab 0x29B0
GTBYTA       .equlab 0x29BB
GTBYTO       .equlab 0x29B2
GTCNTR       .equlab 0xB8D
GTFEN1       .equlab 0x20EB
GTFEND       .equlab 0x20E8
GTLINK       .equlab 0x224E
GTLNKA       .equlab 0x2247
GTO          .equlab 0x1191
GTOL         .equlab 0x118C
GTONN        .equlab 0x2959
GTO_5        .equlab 0x29AA
GTRMAD       .equlab 0x800
GTSRCH       .equlab 0x24DF
HMSDV        .equlab 0x19E5
HMSMP        .equlab 0x19E7
HMS_H        .equlab 0x1193
HMS_MINUS    .equlab 0x1045
HMS_PLUS     .equlab 0x1032
H_HMS        .equlab 0x1199
IN3B         .equlab 0x2A65
INBCHS       .equlab 0x2E0A
INBYT        .equlab 0x29E6
INBYT0       .equlab 0x29E3
INBYT1       .equlab 0x29EA
INBYTC       .equlab 0x29E4
INBYTJ       .equlab 0x2E0C
INBYTP       .equlab 0x29E5
INCAD        .equlab 0x29CF
INCAD2       .equlab 0x29D3
INCADA       .equlab 0x29D6
INCADP       .equlab 0x29D1
INCGT2       .equlab 0x286
IND          .equlab 0xDB2
IND21        .equlab 0xDC4
INEX         .equlab 0x2A4A
INLIN        .equlab 0x2876
INLIN2       .equlab 0x29F6
INPTDG       .equlab 0x8A0
INSHRT       .equlab 0x2A17
INSLIN       .equlab 0x29F4
INSSUB       .equlab 0x23B2
INSTR        .equlab 0x2A73
INT          .equlab 0x1177
INTARG       .equlab 0x7E1
INTFRC       .equlab 0x193B
INTINT       .equlab 0x2FB
INTXC        .equlab 0x2A7D
IORUN        .equlab 0x27E4
ISG          .equlab 0x119E
KEYOP        .equlab 0x68A
KYOPCK       .equlab 0x693
LASTX        .equlab 0x1228
LBL          .equlab 0x11A4
LD90         .equlab 0x1995
LDDP10       .equlab 0xB1E
LDD_P_       .equlab 0xB1D
LDSST0       .equlab 0x797
LEFTJ        .equlab 0x2BF7
LINN1A       .equlab 0x2A93
LINNM1       .equlab 0x2A90
LINNUM       .equlab 0x2A8B
LN           .equlab 0x11A6
LN10         .equlab 0x1B45
LN1_PLUS_X   .equlab 0x1220
LN560        .equlab 0x1BD3
LNAP         .equlab 0x1A8A
LNC10        .equlab 0x1AAE
LNC10_       .equlab 0x1AAD
LNC20        .equlab 0x1ABD
LNSUB        .equlab 0x19F9
LNSUB_MINUS  .equlab 0x19F8
LOAD3        .equlab 0x14FA
LOG          .equlab 0x11AC
LSWKUP       .equlab 0x180
MASK         .equlab 0x2C88
MEAN         .equlab 0x11B9
MEMCHK       .equlab 0x205
MEMLFT       .equlab 0x5A1
MESSL        .equlab 0x7EF
MIDDIG       .equlab 0xDE0
MINUS        .equlab 0x1054
MOD          .equlab 0x104F
MOD10        .equlab 0x195C
MODE         .equlab 0x134D
MODE1        .equlab 0x134F
MOVREG       .equlab 0x215C
MP1_10       .equlab 0x184F
MP2_10       .equlab 0x184D
MP2_13       .equlab 0x1852
MPY150       .equlab 0x1865
MSG          .equlab 0x1C6B
MSG105       .equlab 0x1C80
MSG110       .equlab 0x1C86
MSGA         .equlab 0x1C6C
MSGAD        .equlab 0x1C18
MSGDE        .equlab 0x1C22
MSGDLY       .equlab 0x37C
MSGE         .equlab 0x1C71
MSGML        .equlab 0x1C2D
MSGNE        .equlab 0x1C38
MSGNL        .equlab 0x1C3C
MSGNO        .equlab 0x1C64
MSGOF        .equlab 0x1C4F
MSGPR        .equlab 0x1C43
MSGRAM       .equlab 0x1C67
MSGROM       .equlab 0x1C6A
MSGTA        .equlab 0x1C5F
MSGWR        .equlab 0x1C56
MSGX         .equlab 0x1C75
MSGYES       .equlab 0x1C62
MULTIPLY     .equlab 0x105C
NAM40        .equlab 0xF34
NAM44_       .equlab 0xF7D
NAME20       .equlab 0xEE6
NAME21       .equlab 0xEE9
NAME33       .equlab 0xEEF
NAME37       .equlab 0xF09
NAME4A       .equlab 0xFA4
NAME4D       .equlab 0xFAC
NAMEA        .equlab 0xED9
NBYTA0       .equlab 0x2D04
NBYTAB       .equlab 0x2D06
NEXT         .equlab 0xE50
NEXT1        .equlab 0xE45
NEXT2        .equlab 0xE48
NEXT3        .equlab 0xE4B
NFRC         .equlab 0xF1
NFRENT       .equlab 0xC4
NFRFST       .equlab 0xF7
NFRKB        .equlab 0xC7
NFRKB1       .equlab 0xC6
NFRNC        .equlab 0xA5
NFRNIO       .equlab 0x106
NFRPR        .equlab 0xEE
NFRPU        .equlab 0xF0
NFRSIG       .equlab 0xC2
NFRST_PLUS   .equlab 0xBEE
NFRX         .equlab 0xCC
NFRXY        .equlab 0xDA
NLT000       .equlab 0xE91
NLT020       .equlab 0xEA0
NLT040       .equlab 0xEAA
NM44_5       .equlab 0xF7E
NOPRT        .equlab 0x15B
NOREG9       .equlab 0x95E
NOSKP        .equlab 0x1619
NOTFIX       .equlab 0xADD
NRM10        .equlab 0x1870
NRM11        .equlab 0x1871
NRM12        .equlab 0x1872
NRM13        .equlab 0x1884
NROOM3       .equlab 0x28C2
NULTST       .equlab 0xEC6
NULT_        .equlab 0xE65
NULT_3       .equlab 0xE7C
NULT_5       .equlab 0xE8F
NWGOOS       .equlab 0x7D4
NXBYT3       .equlab 0x29B7
NXBYTA       .equlab 0x29B9
NXBYTO       .equlab 0x2D0B
NXL1B        .equlab 0x2B23
NXL3B2       .equlab 0x2B63
NXLCHN       .equlab 0x2B49
NXLDEL       .equlab 0x2AFD
NXLIN        .equlab 0x2B14
NXLIN3       .equlab 0x2B5F
NXLINA       .equlab 0x2B1F
NXLSST       .equlab 0x2AF7
NXLTX        .equlab 0x2B77
NXTBYT       .equlab 0x2D07
OCT          .equlab 0x1330
OFF          .equlab 0x11C8
OFFSHF       .equlab 0x750
OFSHFT       .equlab 0x749
ONE_BY_X     .equlab 0x11D6
ONE_BY_X10   .equlab 0x188B
ONE_BY_X13   .equlab 0x188E
OPROMT       .equlab 0x2E4C
OUTLCD       .equlab 0x2C80
OUTROM       .equlab 0x2FEE
OVFL10       .equlab 0x1429
P10RTN       .equlab 0x2AC
P6RTN        .equlab 0x1670
PACH10       .equlab 0x3EC
PACH11       .equlab 0x3F5
PACH12       .equlab 0x3FC
PACH4        .equlab 0x3E2
PACK         .equlab 0x11E7
PACKE        .equlab 0x2002
PACKN        .equlab 0x2000
PAK200       .equlab 0x2055
PAKEND       .equlab 0x20AC
PAKSPC       .equlab 0x20F2
PAR111       .equlab 0xCED
PAR112       .equlab 0xCF5
PARA06       .equlab 0xD22
PARA60       .equlab 0xD35
PARA61       .equlab 0xD37
PARA75       .equlab 0xD49
PARB40       .equlab 0xD99
PARS05       .equlab 0xC34
PARS56       .equlab 0xC93
PARS75       .equlab 0xCCD
PARSDE       .equlab 0xC90
PARSE        .equlab 0xC05
PARSEB       .equlab 0xD6D
PATCH1       .equlab 0x21DC
PATCH2       .equlab 0x21E1
PATCH3       .equlab 0x21EE
PATCH5       .equlab 0x21F3
PATCH6       .equlab 0x1C06
PATCH9       .equlab 0x1C03
PCKDUR       .equlab 0x16FC
PCT          .equlab 0x1061
PCTCH        .equlab 0x11EC
PGMAON       .equlab 0x956
PI           .equlab 0x1242
PI_BY_2      .equlab 0x199A
PKIOAS       .equlab 0x2114
PLUS         .equlab 0x104A
PMUL         .equlab 0x1BE9
POWER_OF_TEN .equlab 0x12CA
PR10RT       .equlab 0x372
PR14RT       .equlab 0x1365
PR15RT       .equlab 0x22DF
PR3RT        .equlab 0xEDD
PROMF1       .equlab 0x5CB
PROMF2       .equlab 0x5D3
PROMFC       .equlab 0x5C7
PROMPT       .equlab 0x1209
PSE          .equlab 0x11FC
PSESTP       .equlab 0x3AC
PTBYTA       .equlab 0x2323
PTBYTM       .equlab 0x2921
PTBYTP       .equlab 0x2328
PTLINK       .equlab 0x231A
PTLNKA       .equlab 0x231B
PTLNKB       .equlab 0x2321
PUTPC        .equlab 0x2337
PUTPCA       .equlab 0x2339
PUTPCD       .equlab 0x232C
PUTPCF       .equlab 0x2331
PUTPCL       .equlab 0x2AF3
PUTPCX       .equlab 0x232F
PUTREG       .equlab 0x215E
P_R          .equlab 0x11DC
QUTCAT       .equlab 0x3D5
RAD          .equlab 0x111F
RAK06        .equlab 0xC7F
RAK60        .equlab 0x6FA
RAK70        .equlab 0x70A
RCL          .equlab 0x122E
RCSCR        .equlab 0x1934
RCSCR_       .equlab 0x1932
RDN          .equlab 0x1252
RDNSUB       .equlab 0x14E9
REGLFT       .equlab 0x59A
RFDS55       .equlab 0x949
RG9LCD       .equlab 0x8EF
RMCK05       .equlab 0x27EC
RMCK10       .equlab 0x27F3
RMCK15       .equlab 0x27F4
RND          .equlab 0x1257
ROLBAK       .equlab 0x2E42
ROLLUP       .equlab 0x1260
ROMCHK       .equlab 0x27E6
ROMH05       .equlab 0x66C
ROMH35       .equlab 0x678
ROMHED       .equlab 0x66A
ROUND        .equlab 0xA35
ROW0         .equlab 0x2766
ROW10        .equlab 0x2A6
ROW11        .equlab 0x25AD
ROW12        .equlab 0x2743
ROW120       .equlab 0x519
ROW933       .equlab 0x467
ROW940       .equlab 0x487
RST05        .equlab 0x9B
RSTANN       .equlab 0x759
RSTKB        .equlab 0x98
RSTMS0       .equlab 0x38E
RSTMS1       .equlab 0x390
RSTMSC       .equlab 0x392
RSTSEQ       .equlab 0x384
RSTSQ        .equlab 0x385
RSTST        .equlab 0x8A7
RTJLBL       .equlab 0x14C9
RTN          .equlab 0x125C
RTN30        .equlab 0x272F
RTOD         .equlab 0x198C
RUN          .equlab 0x7C2
RUNING       .equlab 0x108
RUNNK        .equlab 0x11D
RUN_STOP     .equlab 0x1218
RW0110       .equlab 0x4E9
RW0141       .equlab 0x4F1
R_D          .equlab 0x120E
R_P          .equlab 0x11C0
R_SCAT       .equlab 0xBB7
R_SUB        .equlab 0x14ED
SARO21       .equlab 0x2640
SARO22       .equlab 0x2641
SAROM        .equlab 0x260D
SAVR10       .equlab 0x27D5
SAVRC        .equlab 0x27DF
SAVRTN       .equlab 0x27D3
SCI          .equlab 0x1265
SCROL0       .equlab 0x2CDE
SCROLL       .equlab 0x2CDC
SD           .equlab 0x1D10
SEARC1       .equlab 0x2434
SEARCH       .equlab 0x2433
SEPXY        .equlab 0x14D2
SERR         .equlab 0x24E8
SETQ_P       .equlab 0xB15
SETSST       .equlab 0x17F9
SF           .equlab 0x1269
SGTO19       .equlab 0x25C9
SHF10        .equlab 0x186D
SHF40        .equlab 0x186C
SHIFT        .equlab 0x1348
SIGMA        .equlab 0x1C88
SIGMA_MINUS  .equlab 0x1271
SIGMA_PLUS   .equlab 0x126D
SIGN         .equlab 0x1337
SIGREG       .equlab 0x1277
SIN          .equlab 0x1288
SINFR        .equlab 0x1947
SINFRA       .equlab 0x194A
SIZE         .equlab 0x1292
SIZSUB       .equlab 0x1797
SKP          .equlab 0x162E
SKPDEL       .equlab 0x2349
SKPLIN       .equlab 0x2AF9
SNR10        .equlab 0x243F
SNR12        .equlab 0x2441
SNROM        .equlab 0x2400
SQR10        .equlab 0x18BE
SQR13        .equlab 0x18C1
SQRT         .equlab 0x1298
SRBMAP       .equlab 0x2FA5
SST          .equlab 0x129E
SSTBST       .equlab 0x22DD
SSTCAT       .equlab 0xBB4
STATCK       .equlab 0x1CC8
STAYON       .equlab 0x12A3
STBT10       .equlab 0x2EA3
STBT30       .equlab 0x2FE0
STBT31       .equlab 0x2FE5
STDEV        .equlab 0x11B2
STFLGS       .equlab 0x16A7
STK          .equlab 0xDF3
STK00        .equlab 0xDFA
STK04        .equlab 0xE00
STMSGF       .equlab 0x37E
STO          .equlab 0x10DA
STOLCC       .equlab 0x2E5B
STOP         .equlab 0x1215
STOPS        .equlab 0x3A7
STOPSB       .equlab 0x3A9
STORFC       .equlab 0x7E8
STOST0       .equlab 0x13B
STO_DIVIDE   .equlab 0x12C1
STO_MINUS    .equlab 0x12B9
STO_MULTIPLY .equlab 0x12A8
STO_PLUS    .equlab 0x12B0
STSCR       .equlab 0x1922
STSCR_      .equlab 0x1920
SUBONE      .equlab 0x1802
SUMCHK      .equlab 0x1667
SUMCK2      .equlab 0x1669
TAN         .equlab 0x1282
TBITMA      .equlab 0x2F7F
TBITMP      .equlab 0x2F81
TEN_TO_X    .equlab 0x1BF8
TEXT        .equlab 0x2CAF
TGSHF1      .equlab 0x1FE7
TODEC       .equlab 0x1FB3
TOGSHF      .equlab 0x1FE5
TONE        .equlab 0x12D0
TONE7       .equlab 0x1716
TONE7X      .equlab 0x16DB
TONEB       .equlab 0x16DD
TONSTF      .equlab 0x54
TOOCT       .equlab 0x1F79
TOPOL       .equlab 0x1D49
TOREC       .equlab 0x1E75
TRC10       .equlab 0x19A1
TRC30       .equlab 0x1E38
TRCS10      .equlab 0x1E57
TRG100      .equlab 0x1E78
TRG240      .equlab 0x1ED1
TRG430      .equlab 0x1F5B
TRGSET      .equlab 0x21D4
TSTMAP      .equlab 0x14A1
TXRW10      .equlab 0x4F6
TXTLB1      .equlab 0x2FC6
TXTLBL      .equlab 0x2FC7
TXTROM      .equlab 0x4F5
TXTROW      .equlab 0x4F2
TXTSTR      .equlab 0x4F6
UPLINK      .equlab 0x2235
VIEW        .equlab 0x12D6
WKUP10      .equlab 0x184
WKUP21      .equlab 0x1A7
WKUP25      .equlab 0x1BA
WKUP70      .equlab 0x1F5
WKUP80      .equlab 0x1FF
XARCL       .equlab 0x1696
XASHF       .equlab 0x1748
XASN        .equlab 0x276A
XASTO       .equlab 0x175C
XAVIEW      .equlab 0x364
XBAR        .equlab 0x1CFE
XBAR_       .equlab 0x1D07
XBEEP       .equlab 0x16D1
XBST        .equlab 0x2250
XCAT        .equlab 0xB80
XCF         .equlab 0x164D
XCLSIG      .equlab 0x14B0
XCLX1       .equlab 0x1102
XCOPY       .equlab 0x2165
XCUTB1      .equlab 0x91
XCUTE       .equlab 0x15B
XCUTEB      .equlab 0x90
XDEG        .equlab 0x171C
XDELET      .equlab 0x22AF
XDSE        .equlab 0x159F
XECROM      .equlab 0x2F4A
XEND        .equlab 0x2728
XEQ         .equlab 0x1328
XEQC01      .equlab 0x24EA
XFS         .equlab 0x1645
XFT100      .equlab 0x18EC
XGA00       .equlab 0x248D
XGI         .equlab 0x24C7
XGI07       .equlab 0x24DA
XGI57       .equlab 0x24C1
XGNN10      .equlab 0x2512
XGNN12      .equlab 0x2514
XGNN40      .equlab 0x255D
XGOIND      .equlab 0x1323
XGRAD       .equlab 0x1726
XGTO        .equlab 0x2505
XISG        .equlab 0x15A0
XLN1_PLUS_X .equlab 0x1B73
XMSGPR      .equlab 0x56D
XNNROW      .equlab 0x26
XPACK       .equlab 0x2000
XPRMPT      .equlab 0x3A0
XRAD        .equlab 0x1722
XRDN        .equlab 0x14BD
XRND        .equlab 0xA2F
XROLLUP     .equlab 0x14E5
XROM        .equlab 0x2FAF
XROMNF      .equlab 0x2F6C
XROW1       .equlab 0x74
XRS45       .equlab 0x7BE
XRTN        .equlab 0x2703
XR_S        .equlab 0x79D
XSCI        .equlab 0x16C0
XSF         .equlab 0x164A
XSGREG      .equlab 0x1659
XSIGN       .equlab 0xFF4
XSIZE       .equlab 0x1795
XSST        .equlab 0x2260
XSTYON      .equlab 0x1411
XTOHRS      .equlab 0x19B2
XTONE       .equlab 0x16DE
XVIEW       .equlab 0x36F
XXEQ        .equlab 0x252F
XX_EQ_0     .equlab 0x1606
XX_EQ_Y     .equlab 0x1614
XX_GT_0     .equlab 0x15F1
XX_GT_Y     .equlab 0x15F8
XX_LE_0     .equlab 0x160D
XX_LE_0A    .equlab 0x1609
XX_LE_Y     .equlab 0x1601
XX_LT_0     .equlab 0x15FA
XX_LT_Y     .equlab 0x15EF
XX_NE_0     .equlab 0x1611
XX_NE_Y     .equlab 0x1629
XY_TO_X     .equlab 0x1B11
X_BY_Y13    .equlab 0x1893
X_EQ_0      .equlab 0x130E
X_EQ_Y      .equlab 0x1314
X_GT_0      .equlab 0x131A
X_GT_Y      .equlab 0x1320
X_LE_0      .equlab 0x12EF
X_LE_Y      .equlab 0x12F6
X_LT_0      .equlab 0x12E8
X_LT_Y      .equlab 0x1308
X_NE_0      .equlab 0x12DC
X_NE_Y      .equlab 0x12E2
X_TO_2      .equlab 0x106B
X_XCHNG     .equlab 0x124C
X_XCHNG_Y   .equlab 0x12FC
Y_MINUS_X   .equlab 0x1421
Y_TO_X      .equlab 0x102A

