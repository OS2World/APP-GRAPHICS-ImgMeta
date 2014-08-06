/* Install ImgMeta 
*/

nok = RxFuncAdd("SysLoadFuncs",  "RexxUtil", "SysLoadFuncs") ;rc = SysLoadFuncs();

HomePath = directory();

say "Install to "HomePath"? (Y/N)";

if Translate( SysGetKey('NoEcho') ) = "Y" then NOP;
else;do
   say "No installation";
   exit;
end;

ok = SysFileTree("ImgMeta.exe","files.","F");
if files.0 = 1 then NOP;
else;do
   say "ImgMeta.exe missing - installation abandoned";
   exit;
end;

/* --------------------------------------  */
/* Create ImgMeta folder on WPS-desktop:   */
/* --------------------------------------  */

FolderID = "<ImgMeta Objects>";

ok = SysCreateObject(   "WPFolder",           ,
                        "ImgMeta",            ,
                        "<WP_DESKTOP>",       ,
                        "OBJECTID="FolderID";ICONFILE=Folder1.ico",  ,
                        "Replace"             ,
                    );

if ok then
   say "Folder-object successfully created";
else;
   say "Error creating Folder-object: Code="ok;

/* --------------------------------------  */
/* Create ImgMeta program-object:          */
/* --------------------------------------  */

ok = SysCreateObject(   "WpProgram",                                             ,
                        "ImgMeta"||"0D0A"x||"Append Meta-Info to Image-Files", 	,
                        FolderID,                                                ,
                        "EXENAME="HomePath"\ImgMeta.exe;ICONFILE="HomePath"\ImgMeta.ico;"||       ,
                        "STARTUPDIR="HomePath"\",                        ,
                        "Replace"                                       ,
                    );

if ok then
   say "Program-object successfully created";
else;
   say "Error creating program-object: Code="ok;


say "ImgMeta installation successfully completed";

exit;
