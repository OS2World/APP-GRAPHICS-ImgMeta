/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
    end
    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
    __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
    if __vrlsWait then do
        call VRFlush
    end
    __vrlsHWnd = VRLoad( VRWindow(), VRWindowPath(), arg(1) )
    if __vrlsHWnd = '' then signal __vrlsDone
    if __vrlsWait \= 1 then signal __vrlsDone
    call VRSet __vrlsHWnd, 'WindowMode', 'Modal' 
    __vrlsTmp = __vrlsWindows.0
    if( DataType(__vrlsTmp) \= 'NUM' ) then do
        __vrlsTmp = 1
    end
    else do
        __vrlsTmp = __vrlsTmp + 1
    end
    __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
    __vrlsWindows.0 = __vrlsTmp
    do while( VRIsValidObject( VRWindow() ) = 1 )
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
    end
    __vrlsTmp = __vrlsWindows.0
    __vrlsWindows.0 = __vrlsTmp - 1
    call VRWindow __vrlsWindows.__vrlsTmp 
    __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         CN_Files_ContextMenu
*/
CN_Files_ContextMenu: 

/* ++
Rec = VRInfo("Record");
if Rec <> "" then RETURN -1;
++ */


MenuParent = "MMList_Fields";

/* zuerst alle alten lîschen:       */
ChldList = VRGet( MenuParent, "Userdata" );
do i = 1 to words( ChldList )
   ok = VRDestroy( word( ChldList,i ) );
end;

ok = VRMethod("CN_Files", "GetFieldList", "Flds." );

do i = 1 to Flds.0

   ColName = VRMethod("CN_Files", "GetFieldAttr", Flds.i, "Title" );
   if strip(ColName) <> ""  ,
    & VRMethod("CN_Files", "GetFieldAttr", Flds.i, "Visible") then do
      MenHnd = VRCreate( MenuParent, "MENUITEM",   ,
                        "Caption", ColName,    ,
                        "Click", "Call CN_Files_ContextMenu_Select "Flds.i";"        ,
                       );

      /* erstellen Wortliste der generierten Menuitems:         */
      ok = VRSet( MenuParent, "Userdata", VRGet( MenuParent, "Userdata" ) MenHnd );
   end;
end;


Call VRMethod "MMList", "Popup";

return

---------------------
CN_Files_ContextMenu_Select:
hnd = arg(1);

ok = VRSet("CN_Files", "Painting", 0);

ok = VRSet("CN_Files", "DetailSort", hnd);
ok = VRMethod("CN_Files", "SortRecords" );

ok = VRSet("CN_Files", "Painting", 1);

return;
/*:VRX         CN_Files_DoubleClick
*/
CN_Files_DoubleClick: 

Rec = VRInfo("Record");
if Rec = "" then RETURN -1;

IMG_FS = VRMethod("CN_Files", "GetRecordAttr", Rec, "Filename");

Call ZInfo2EF IMG_FS;

return

/*:VRX         DT_1_ContextMenu
*/
DT_1_ContextMenu: 
DT_2_ContextMenu: 
DT_3_ContextMenu: 
DT_4_ContextMenu: 
DT_5_ContextMenu: 

!CurObj = VRGet( VRInfo("Object"), "Name");

ok = VRSet("MMCapt_Name", "Caption", "Edit '"VRGet(!CurObj,"Caption")"':" );

parse value !CurObj with DT "_" InfoNo "_" Muell;

ok = VRSet("MMCapt_Active",   "Checked", (Activs.InfoNo = "1") );
ok = VRSet("MMCapt_InActive", "Checked", (Activs.InfoNo = "0") );

Call VRMethod "MMCapt", "Popup";
return

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         Init
*/
Init:

nok = RxFuncAdd("SysLoadFuncs",  "RexxUtil", "SysLoadFuncs") ;rc = SysLoadFuncs();
nok = RxFuncAdd("RxExtra",       "RxExtras", "RxExtra")      ;rc = RxExtra("LOAD");
nok = RxFuncAdd("FileLoadFuncs", "FILEREXX", "FileLoadFuncs");rc = FileLoadFuncs();

if 1 then ok = VRRedirectStdIO("OFF"); /* Makes console invisible   */

YGlob.YPGMName = "ImgMeta";

INIFile = YGlob.YPGMName".ini";

/* ------------------------------                  */
/* Ermitteln Country-Code etc.:                    */
/* ------------------------------                  */
YLang_Ger = 1;
YLang_Eng = 2;
YLang_Esp = 3;

rc  = RxQueryCountryInfo( "Countrydata." )
CountryCode = Countrydata.Country_Code;

Call ZSet_YLang;

if(0) then  YGlob.YLang = YLang_Eng;    /* ++ test only ++  */

Call XSay "Welcome to "YGlob.YPGMName", your country-code is "CountryCode".";

/* ------------------------------  */
/* Sprach-abhÑngige Texte setzen:  */
/* ------------------------------  */
if YGlob.YLang =  YLang_Ger then do
   ok = VRSet("MMHelp", "Helptext", "(HelpD.hlp)" );
   ok = VRSet("MMHelp", "Caption", "~Hilfe" );
   ok = VRSet("MMFile", "Caption", "~Datei" );

   ok = VRSet("PICT_1",   "HintText", "Rechte Maustaste clicken fÅr Kontext-MenÅ" );
   ok = VRSet("CN_Files", "HintText", "Doppelklicken um ein Bild anzuzeigen oder: Rechte Maustaste fÅr Kontext-MenÅ" );
end;

/* ----------------------------------       */
/* Erstmal schauen, ob GBM verfÅgbar:       */
/* ----------------------------------       */
ok1 = SysSearchPath("PATH", "gbmhdr.exe");
ok2 = SysSearchPath("PATH", "gbmsize.exe");

if ok1 = "" | ok2 = "" then do
   ok = VRMessage( VRWindow(), "You need to have gbmhdr.exe and gbmsize.exe on your system, reachable via PATH." || "0D0A"x,
                             ||"You can download the GBM-package from http://heikon.home.tlink.de/",    ,
                               "ImgMeta cannot run", "E" );
   Call Quit;
end;


TempBMPName = directory() || "\" || SysTempFileName("$Tmp???.bmp");

Capts.  = "";   /* { captions je Info-n }   */
Activs. = "";   /* [ 0 | 1 ]                */

/* --------------------------------------       */
/* Info-Captions laden / Default setzen:        */
/* --------------------------------------       */
NumInfos = 5;

Call ZBuild_Info;

/* ----------------     */
/* Container bauen:     */
/* ----------------     */

hndFN   = VRMethod("CN_Files", "AddField", "string", "FileName" );
hndFD   = VRMethod("CN_Files", "AddField", "string", "FileDate" );
hndFT   = VRMethod("CN_Files", "AddField", "string", "FileTime" );

do i = 1 to NumInfos
   _Z = 'hndFIf'i' = VRMethod("CN_Files", "AddField", "string", Capts.'i' );'; interpret _Z;
end;

Call ZBuild_Colheaders;

ok = VRMethod("CN_Files", "SetFieldAttr", hndFN, "VertJustification", "TOP" );
ok = VRSet( "CN_Files",   "LastSplitField", hndFT );
ok = VRSet( "CN_Files",   "SplitBarLeft", 1600 );

/* Verankern orig-Dimens (fÅr Resize):      */
ok = VRSet(VRWindow(), "Userdata", VRGet(VRWindow(),"Width") VRGet(VRWindow(),"Height") );

/* ---------------------------      */
/* Options wiederherstellen:        */
/* ---------------------------      */
ok = VRSet("MM_ListOptOnlyYes","Checked", (SysINI( INIFile, "ListOpt", "ShowOnly")=1) );
ok = VRSet("MM_ListOptOnlyNo", "Checked", (SysINI( INIFile, "ListOpt", "ShowOnly")<>1) );

/* ---------------------------      */
/* Img-Buttons dimensionieren:      */
/* ---------------------------      */

ok = VRSet("PICT_Prev", "PicturePath", "Arrow_Up.bmp");
ok = VRSet("PICT_Prev", "Border", 0);
ok = VRSet("PICT_Prev", "Width",  16 * VRMethod("Screen", "PixelsToTwips",1) );
ok = VRSet("PICT_Prev", "Height", 32 * VRMethod("Screen", "PixelsToTwips",1) );

ok = VRSet("PICT_Next", "PicturePath", "Arrow_Dn.bmp");
ok = VRSet("PICT_Next", "Border", 0);
ok = VRSet("PICT_Next", "Width",  16 * VRMethod("Screen", "PixelsToTwips",1) );
ok = VRSet("PICT_Next", "Height", 32 * VRMethod("Screen", "PixelsToTwips",1) );
ok = VRSet("PICT_Next", "Top",  (VRGet("GB_Img", "Height")+VRGet("GB_Img", "Top")) - VRGet("PICT_Next", "Height") );

    window = VRWindow()
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return;

/* ------------------------------       */
/* XSay: Neu: 'REPL'-Param              */
/*       fÅr im Stand lfd. Zeilen       */
/* ------------------------------       */
XSay: procedure
What = arg(1);
Aux  = arg(2);  /* erklÑrender Text, nur wenn What <> Leer   */
Mode = arg(3);  /* "REPL" | ""          */
LB   = arg(4);  /* alternative ListBox  */

if strip(What) = "" | What="TOF" | What="BOF" then return;

if Aux <> "" then
   What = Aux||What;

What = time()"."left(time("LONG"),2)"> "What;

if LB = "" | (1) then
   LBObj = "LB_XSay";
else;
   LBObj = LB;

if Mode= "REPL" then do
   ok = VRSet( LBObj, "Painting", 0);
   Indx = VRGet( LBObj, "Count");
   ok = VRMethod( LBObj, "Delete", Indx);
end;

/* ++ debug: ++ */
if (0) then say What;

ok = VRMethod( LBObj, "Addstring", What);
ok = VRSet( LBObj, "Selected", VRGet( LBObj, "Count"));
ok = VRSet( LBObj, "Painting", 1);
return 0;
/*:VRX         MM_Exit_Click
*/
MM_Exit_Click: 

Call  Quit;

return

/*:VRX         MM_ListBrowse_Click
*/
MM_ListBrowse_Click: 

ImgDir = VRFileDialog( VRWindow(), "Select an image-directory", "OPEN", SysINI(INIFile, "Settings", "ImgDir") );

if ImgDir = "" then RETURN -1;

ImgDir = filespec("drive",ImgDir) || filespec("path",ImgDir);

/* --------------------     */
/* Clear Preview-Image:     */
/* --------------------     */
ok = VRSet("Pict_1", "PicturePath", "");
ok = VRSet("Pict_1", "Visible", 0);
ok = VRSet("DT_6",   "Visible", 1); /* '<preview-image>'    */

ok = SysINI( INIFile, "Settings", "ImgDir", ImgDir );   /* öbergabe fÅr MM_ListCur  */

Call MM_ListCur_Click;

return

/*:VRX         MM_ListCur_Click
*/
MM_ListCur_Click: 

/* --------------------------------------------------------------   */
/* Auflisten current directory:                                     */
/* (dasjenige, das durch den zuletzten LOAD bestimmt worden ist):   */
/* --------------------------------------------------------------   */

ImgDir = SysINI( INIFile, "Settings", "ImgDir" );
if ImgDir = "ERROR:" then do
   ok = VRMessage( VRWindow(), "You must first specify an image directory" );
   RETURN -9;
end;

ok = VRMethod("CN_Files", "RemoveRecord", "ALL" );

ListAll = \VRGet("MM_ListOptOnlyYes","Checked");

ok = VRSet("CN_Files", "Painting", 0 );

ok = SysFileTree( ImgDir"*.*", "files.", "F" );

ok  = VRSet("DT_Leng2", "Caption", "" );    /* LÑngen-Referenzfeld  */

NumMetImgs = 0; /* Images mit Meta-Info     */

do i = 1 to files.0
   IMG_FS = subword( files.i, 5 );

say "files.i="files.i"!";

   infos.0 = 0;

   /* je Image alle mîglichen 5 Infos abklappern:   */
   do j = 1 to NumInfos
      nok = SysGetEA( IMG_FS, ".info"j, "Info" );
      if nok = 0 then do
         if info <> "" then do
            a = infos.0 +1;
            infos.a = info;
            infos.0 = a;
         end;
      end;
      else;do
         NOP;
      end;
   end;
   if infos.0 > 0 | (ListAll) then do
      /* Ja, es waren EAs da: dieses Image in den Container stellen:   */
      NumMetImgs = NumMetImgs+1;
      Rec = VRMethod("CN_Files", "AddRecord" );
      ok  = VRMethod("CN_Files", "SetRecordAttr", Rec, "Filename", IMG_FS );
      IMG_FN = filespec("name",IMG_FS);

      DateTime = ZMakeDateTime(files.i);
      parse value DateTime with Date "-" Time;

      ok  = VRMethod("CN_Files", "SetFieldData",  Rec, hndFN, IMG_FN );
      ok  = VRMethod("CN_Files", "SetFieldData",  Rec, hndFD, Date );
      ok  = VRMethod("CN_Files", "SetFieldData",  Rec, hndFT, Time );
      do j = 1 to infos.0
         _Z = 'ok = VRMethod("CN_Files", "SetFieldData", Rec, hndFIf'j', infos.'j');';  interpret _Z;
      end;

      ok  = VRSet("DT_Leng1", "Caption", IMG_FN );
      if VRGet("DT_Leng1", "Width") > VRGet("DT_Leng2", "Width") then
         ok  = VRSet("DT_Leng2", "Caption", IMG_FN );

   end;
end;
ok = VRSet("CN_Files", "SplitBarLeft", VRGet("DT_Leng2", "Width")+100 );

ok = VRSet("CN_Files", "Caption", ImgDir );
ok = VRSet("CN_Files", "Painting", 1 );

if NumMetImgs = 0 then
   Call XSay "No files with meta-information found in '"ImgDir"'!";

return

/*:VRX         MM_ListOptOnlyNo_Click
*/
MM_ListOptOnlyNo_Click: 

ok = VRSet("MM_ListOptOnlyNo", "Checked",1);
ok = VRSet("MM_ListOptOnlyYes","Checked",0);

ok = SysINI( INIFile, "ListOpt", "ShowOnly", VRGet("MM_ListOptOnlyYes","Checked") );
return

/*:VRX         MM_ListOptOnlyYes_Click
*/
MM_ListOptOnlyYes_Click: 

ok = VRSet("MM_ListOptOnlyYes","Checked",1);
ok = VRSet("MM_ListOptOnlyNo", "Checked",0);

ok = SysINI( INIFile, "ListOpt", "ShowOnly", VRGet("MM_ListOptOnlyYes","Checked") );
return

/*:VRX         MM_Load_Click
*/
MM_Load_Click: 

Bak_Dir = directory();

ImgDir = SysINI( INIFile, "Settings", "ImgDir" );
if ImgDir <> "ERROR:" then
   ok = directory(ImgDir);
else;
   ImgDir = "";

IMG_FS = VRFileDialog( VRWindow(), "Select an image:", "OPEN", ImgDir"*.*" );

ok = directory(Bak_Dir);

if IMG_FS = "" then RETURN;

/* INI saven:       */
ImgDir = filespec("drive",IMG_FS) || filespec("path",IMG_FS);
ok = SysINI( INIFile, "Settings", "ImgDir", ImgDir );

Call ZInfo2EF IMG_FS;

Call MM_ListCur_Click;

return

/*:VRX         MMCapt_Active_Click
*/
MMCapt_Active_Click: 
Call MMCapt_ActiveToggle 1;
return;

MMCapt_InActive_Click: 
Call MMCapt_ActiveToggle 0;
return;

---------------------
MMCapt_ActiveToggle: 
What = arg(1);

/* !CurObj is set           */

parse value !CurObj with DT "_" InfoNo "_" Muell;

Activs.InfoNo = What;

ok = SysINI( INIFile, "Activ", InfoNo, Activs.InfoNo );

Call ZBuild_Info;       /* refresh Info-Tables      */
Call ZBuild_Colheaders; /* refresh Column-Headers   */

return;


/*:VRX         MMCapt_Set_Click
*/
MMCapt_Set_Click: 

/* !CurObj is set           */

parse value !CurObj with DT "_" InfoNo "_" Muell;

Capt = Capts.InfoNo;

ok = VRPrompt( VRWindow(), "Enter new caption", "Capt" );

OldWid = VRGet("DT_"InfoNo, "Width");

ok = VRSet("GB_Info", "Painting", 0);

ok = VRSet("DT_"InfoNo, "Caption", Capt);
_Z = 'ok = VRMethod("CN_Files", "SetFieldAttr", hndFIf'InfoNo', "Title", Capt);'; interpret _Z;

ok = SysINI( INIFile, "Caption", InfoNo, Capt );

/* ----------------------           */
/* Text links ausrichten:           */
/* ----------------------           */
NewWid = VRGet("DT_"InfoNo, "Width");
ok = VRSet("DT_"InfoNo, "Left", VRGet("DT_"InfoNo, "Left") - (NewWid-OldWid));

ok = VRSet("GB_Info", "Painting", 1);

return;

/*:VRX         MMCapt_Sort_Click
*/
MMCapt_Sort_Click: 

/* !CurObj is set           */

parse value !CurObj with DT "_" InfoNo "_" Muell;

_Z = 'ok = VRSet("CN_Files", "DetailSort", hndFIf'InfoNo');'; interpret _Z;

ok = VRSet("CN_Files", "Painting", 0);

ok = VRMethod("CN_Files", "SortRecords" );

ok = VRSet("CN_Files", "Painting", 1);

return

/*:VRX         MMHelp_Click
*/
MMHelp_Click: 
Call VRMethod "MMHelp", "InvokeHelp";

return

/*:VRX         MMPict_LoadExt_Click
*/
MMPict_LoadExt_Click: 

IMG_FS = VRGet("Pict_1", "Userdata");

Call ZLoad_Ext IMG_FS;

Call PB_Save_Click "restored";   /* restore Meta-Data  (IMG_FS is set)  */

return;

/*:VRX         PB_Exit_Click
*/
PB_Exit_Click: 

if VRInfo("AltPressed") = 1 then do
   ok =  VRRedirectStdIO("ON");  /* Show console!     */
   say "Console made visible by explicit request!";

   return;
end;

if VRInfo("ShiftPressed") = 1 then do
   ok =  VRRedirectStdIO("OFF");  /* Make Show console invisibl!     */
   Call Xsay "Console made invisible by explicit request!";
   return;
end;

if VRInfo("CtrlPressed") = 1 then do
   !YSay = 1;  /* make debugging-info visible     */
   Call XSay "debugging-info made visible by explicit request!";
   return;
end;

    Call MM_Exit_Click;

return

/*:VRX         PB_Save_Click
*/
PB_Save_Click: 
What = arg(1);  /* [ "" | "restored" ]  */

nok = 1;

do i = 1 to NumInfos
   Data = VRGet("EF_Info"i,"Value");
   if Data <> "<no data>" then do
      nok = SysPutEA( IMG_FS, ".info"i, Data ); say "nok"i"="nok"!";
   end;
end;

if nok=0 then do
   if What = "" then What = "appended";
   Call XSay "Info-data successfully "What" for '"IMG_FS"'";
end;

return;

/*:VRX         Pict_1_Click
*/
Pict_1_Click: 
Call MMPict_LoadExt_Click;
return

/*:VRX         Pict_1_ContextMenu
*/
Pict_1_ContextMenu: 

Call VRMethod "MMPict", "Popup";

return

/*:VRX         Pict_Next_Click
*/
Pict_Next_Click: 

return

/*:VRX         Pict_Prev_Click
*/
Pict_Prev_Click: 

return

/*:VRX         Quit
*/
Quit:

ok = SysFileDelete( TempBMPName );

ok = VRRedirectStdIO("OFF"); /* Makes console invisible  */

    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return

/*:VRX         Window1_Close
*/
Window1_Close:
    call Quit
return

/*:VRX         Window1_Resize
*/
Window1_Resize: 

Delta_Width  = VRGet(VRWindow(), "Width")  - word( VRGet(VRWindow(), "Userdata"), 1 );
Delta_Height = VRGet(VRWindow(), "Height") - word( VRGet(VRWindow(), "Userdata"), 2 );

say "Delta_Width="Delta_Width",Delta_Height="Delta_Height"!";

ok = VRSet("CN_Files", "Width",  VRGet("CN_Files", "Width")  + Delta_Width );
ok = VRSet("CN_Files", "Height", VRGet("CN_Files", "Height") + Delta_Height );

ok = VRSet("GB_List", "Width",  VRGet("GB_List", "Width")  + Delta_Width );
ok = VRSet("GB_List", "Height", VRGet("GB_List", "Height") + Delta_Height );


ok = VRSet("GB_XSay", "Painting", 0 );
ok = VRSet("PB_Exit", "Painting", 0 );
ok = VRSet("GB_XSay", "Top", VRGet("GB_XSay", "Top") + Delta_Height );
ok = VRSet("PB_Exit", "Top", VRGet("PB_Exit", "Top") + Delta_Height );
ok = VRSet("GB_XSay", "Painting", 1 );
ok = VRSet("PB_Exit", "Painting", 1 );

/* Verankern orig-Dimens (fÅr Resize):      */
ok = VRSet(VRWindow(), "Userdata", VRGet(VRWindow(),"Width") VRGet(VRWindow(),"Height") );

return

/*:VRX         ZBuild_Colheaders
*/
ZBuild_Colheaders: 

do i = 1 to NumInfos
   _Z = 'ok = VRMethod("CN_Files", "SetFieldAttr", hndFIf'i', "visible", Activs.'i' );'; interpret _Z;
end;

return

/*:VRX         ZBuild_Info
*/
ZBuild_Info: 

/* dyn. aufbauen Tabelle 'Capts.':              */
do i = 1 to NumInfos
   Capt = SysINI( INIFile, "Caption", i );
   if Capt = "ERROR:" then
      Capts.i = "Info-"i;   /* Default setzen   */
   else;
      Capts.i = Capt;

   ok = VRSet("DT_"i, "Caption", Capts.i );
   ok = VRSet("DT_"i, "Left", VRGet("EF_Info"i, "Left") - VRGet("DT_"i, "Width") - 40 );
end;

/* dyn. aufbauen Tabelle 'Activs.':             */
do i = 1 to NumInfos
   Activ = SysINI( INIFile, "Activ", i );
   if Activ = "0" then do
      Activs.i = "0";
      ok = VRSet("EF_Info"i, "BackColor", "PaleGray", "ReadOnly", 1, "TabStop", 0, "Enabled", 0 );
   end;
   else;do
      Activs.i = "1";
      ok = VRSet("EF_Info"i, "BackColor", "<default>", "ReadOnly", 0, "TabStop", 1, "Enabled", 1 );
   end;

end;

return

/*:VRX         ZInfo2EF
*/
ZInfo2EF: Procedure Expose NumInfos TempBMPName;
IMG_FS = arg(1);

ok = VRSet("Pict_1", "PicturePath", "");

ok = VRSet("GB_Info", "Caption", "Info for file '" || filespec("name",IMG_FS) || "':" );

do i = 1 to NumInfos
   nok = SysGetEA( IMG_FS, ".info"i, "Info" );
   if nok = 0 then do
      if info <> "" then
         ok = VRSet("EF_Info"i, "Value", Info );
      else;
         ok = VRSet("EF_Info"i, "Value", "<no data>" );
   end;
   else;do
      ok = VRSet("DT_Result", "Value", "Error, code="nok );
      LEAVE;
   end;
end;

/* -------------------------------- */
/* Auch Image als Preview anzeigen: */
/* -------------------------------- */

Marg_Top = 6 * VRMethod("Screen", "PixelsToTwips", 1);

ImgDim = X_GetImgSize( IMG_FS, directory() ); /* ++ Version fÅr non-BMPs ++ */
Width  = word(ImgDim,1);
Height = word(ImgDim,2);

if translate( Width ) = "ERROR" then do
   ok = beep(211,444);
   Say "Image '"IMG_FS"' cannot be displayed, probably file not found";
   RETURN -1
end;

/* ++ if Width < Height then do
   Parm = "-w "VRGet("GB_Img","Width") % VRMethod("Screen","PixelsToTwips",1);
end;
else;do ++ */
   Parm = "-h " || (VRGet("GB_Img","Height")-(2*Marg_Top)) % VRMethod("Screen","PixelsToTwips",1);
/* end; */
cmd = 'gbmsize 'Parm' -a "\"' || IMG_FS || '"\"' TempBMPName;
say cmd;
cmd

ok = VRSet("Pict_1", "PicturePath", TempBMPName);

/* Picturebox zentrieren in GB_Img:     */
ok = VRSet("Pict_1", "Top",  ((VRGet("GB_Img","Height")+Marg_Top%2) - VRGet("Pict_1", "Height")) %2 );
ok = VRSet("Pict_1", "Left", (VRGet("GB_Img","Width")  - VRGet("Pict_1", "Width")) %2 );

ok = VRSet("Pict_1", "Userdata", IMG_FS);
ok = VRSet("Pict_1", "Visible", 1);
ok = VRSet("DT_6",   "Visible", 0); /* '<preview-image>'    */

return 0;

/*:VRX         ZLoad_Ext
*/
ZLoad_Ext: Procedure Expose INIFile YGlob.

/* Starten Externes Bildverarbeitungs-Programm:     */

Image_FS = arg(1);

say "Image_FS="Image_FS"!";

/* ---------------------------------        */
/* Externen Programm-Namen besorgen:        */
/* ---------------------------------        */
ExtImag = SysINI(INIFile, "Settings", "ExtImag");

if VRInfo("CtrlPressed") = 1 then ExtImag = "ERROR:";   /* RESET-Funktion       */

if ExtImag = "ERROR:" then do

   ok = VRMessage( VRWindow(), "You must specify your Image-Editor for displaying images",  ,
                               "Only the first time"   ,
                 );

   ExtImag = VRFileDialog( VRWindow(), "Select external image program:", "OPEN", "*.exe" );

   ok = SysINI(INIFile, "Settings", "ExtImag", ExtImag)

   ExtImag = SysINI(INIFile, "Settings", "ExtImag");   /* nochmal...   */

end;

if ExtImag = "ERROR:" then RETURN -1;

/* ---------------------------------        */
/* Externen Editor SYNCHRON starten:        */
/* ---------------------------------        */

Bak_Dir = directory();

Neu_Dir = strip( filespec("drive",ExtImag) || filespec("path",ExtImag), "T", "\" );
ok = directory( Neu_Dir );

ExtImag '"'Image_FS'"';

if RC <> 0 then do
   ok = beep( 111,444 );
   Call XSay "Error starting external image-editor-program '"ExtImag"', code="RC;
end;

ok = directory( Bak_Dir );

return 0;

/*:VRX         ZMakeDateTime
*/
ZMakeDateTime: Procedure
/* ------------------------------                    */
/* Make DateTime: JJ/MM/TT-HH:MM                     */
/* arg1:   Zeile, wie von SysFileTree geliefert      */
/* ------------------------------                    */
   Date  = word( arg(1), 1);
   Time  = word( arg(1), 2);

   /* umwandeln Time von hh:mma/p nach 24-Std-Format:   */
   hhmm = left(Time,length(Time)-1);    /* strip off 'a' / 'p'      */
   parse value hhmm with hh ":" mm
   if right(Time,1) = "p" then do
      if hh < 12 then hh = hh+12        /* '12.01p' bedeutet NICHT 24:01      */
   end
   Time = hh":"mm;

   parse value date with MM "/" TT "/" JJ

   MM = left("",2-length(MM),"0")||MM;        /* aufblasen auf feste LÑnge    */
   TT = left("",2-length(TT),"0")||TT;        /* aufblasen auf feste LÑnge    */
   Time = left("",5-length(Time),"0")||Time;  /* aufblasen auf feste LÑnge    */

   Date = JJ"/"MM"/"TT;

if JJ < 81 then Jahrh = "20";   /* vorher gab's keine PC ...          */
else;           Jahrh = "19";

return Jahrh||Date"-"Time;

/*:VRX         ZSet_YLang
*/
ZSet_YLang: 
YGlob.YLang = 0;

if CountryCode = 40 ,   /* Schweiz         */
 | CountryCode = 41 ,
 | CountryCode = 43 ,
 | CountryCode = 49 then
                    YGlob.YLang = YLang_Ger;

if CountryCode =  3 ,   /* Lateinamerika   */
 | CountryCode = 34     /* Spanien         */
                    then
                    YGlob.YLang = YLang_Esp;

/* Else:        */
if YGlob.YLang = 0  ,
                    then
                    YGlob.YLang = YLang_Eng;

return YGlob.YLang;

