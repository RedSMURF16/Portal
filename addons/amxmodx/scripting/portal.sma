/*
*
*	Portal by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /portal                    "Opens the Portal menu."
*       say_team /portal               "Opens the Portal menu."
*       portal_reload                  "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define ADMIN_ACCESS                ADMIN_RCON
#define PORTAL_KEY                  891277
#define PORTAL_ARRAY_ITEM           pev_iuser1
#define PORTAL_OWNER                pev_iuser1
#define RANDOM_MAX                  2500
#define PORTAL_DEATH_PENALTY        10000.0
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "XenPORTAL_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_PORTAL
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_ARRAY_STRING,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_DLIGHT             = (1 << 0),
    FLAG_SOUND              = (1 << 1),
    FLAG_COOLDOWN           = (1 << 2),
    FLAG_RANDOM             = (1 << 3),
    FLAG_PLAYERS_ONLY       = (1 << 4),

    FLAG_SHOW               = (1 << 5),
    FLAG_GHOST              = (1 << 6),
    FLAG_GROUND             = (1 << 7),
    FLAG_ACTIVE             = (1 << 8),
    FLAG_SOUND_AMBIENT      = (1 << 9),
    FLAG_SOUND_TELEPORT     = (1 << 10),
    FLAG_PLAYING            = (1 << 11),
    FLAG_LOCK               = (1 << 12),
    FLAG_PENDING            = (1 << 13)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum
{
    SPRITE_BASE,
    SPRITE_DEST
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_DEFAULT_SPRITE[MAX_RESOURCE_PATH_LENGTH],
    Array:SETTING_DEFAULT_SOUND_AMBIENT,
    Array:SETTING_DEFAULT_SOUND_TELEPORT,

    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_SPRITE_FRAMERATE,
    Float:SETTING_DEFAULT_SPRITE_OFFSET,
    Float:SETTING_DEFAULT_SPRITE_SCALE,
    SETTING_DEFAULT_SPRITE_COLOR[3],
    SETTING_DEFAULT_SPRITE_ALPHA,
    SETTING_DEFAULT_DLIGHT_RADIUS,
    SETTING_DEFAULT_DLIGHT_COLOR[3],
    SETTING_DEFAULT_DLIGHT_LIFE,
    Float:SETTING_DEFAULT_COOLDOWN[2],
    Float:SETTING_RANDOM_X[2],
    Float:SETTING_RANDOM_Y[2],
    Float:SETTING_RANDOM_Z[2],
    bool:SETTING_STOP_VELOCITY_ON_TELEPORT,
    bool:SETTING_KILL_ON_DESTINATION,
    bool:SETTING_KILL_ON_DESTINATION_WORLD,

    Float:SETTING_MINS[3],
    Float:SETTING_MAXS[3],
    Float:SETTING_SPRITE_MINS[3],
    Float:SETTING_SPRITE_MAXS[3],

    bool:SETTING_PORTAL_LOAD,
    Float:SETTING_PORTAL_CHECK,
    Float:SETTING_PORTAL_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP
}

enum _:PORTAL
{
    PORTAL_ID,
    PORTAL_ITEM,
    PORTAL_FLAGS,
    PORTAL_TEAM,
    PORTAL_SPRITE_BASE,
    PORTAL_SPRITE_DESTINATION,
    PORTAL_NAME[MAX_VALUE_LENGTH],
    PORTAL_MODEL[MAX_RESOURCE_PATH_LENGTH],
    PORTAL_SPRITE[MAX_RESOURCE_PATH_LENGTH],

    Float:PORTAL_ORIGIN_BASE[3],
    Float:PORTAL_ORIGIN_DESTINATION[3],
    Float:PORTAL_ANGLES[3],
    Float:PORTAL_MINS[3],
    Float:PORTAL_MAXS[3],

    Array:PORTAL_SOUND_AMBIENT,
    Array:PORTAL_SOUND_TELEPORT,
    PORTAL_SOUND_AMBIENT_CURRENT[MAX_RESOURCE_PATH_LENGTH],
    Float:PORTAL_SPRITE_FRAMERATE,
    Float:PORTAL_SPRITE_SCALE,
    PORTAL_SPRITE_COLOR[3],
    PORTAL_SPRITE_ALPHA,
    PORTAL_DLIGHT_RADIUS,
    PORTAL_DLIGHT_COLOR[3],
    Float:PORTAL_COOLDOWN[2],

    Float:PORTAL_NEXT_COOLDOWN
}

enum _:PLAYER_DATA
{
    PDATA_PORTAL_GHOST,
    PDATA_PORTAL_MENU,
    bool:PDATA_PORTAL_ACTION,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE,
    MENU_DESTINATION
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_PLACE
}

enum
{
    DESTINATION_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate",
    "menuHandlerDestination"
}

new g_szCN[] = "portal"

new Array:g_aPortal,
    Array:g_aPortalConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdTouch, HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iPortal, g_iPortalConfig,
    g_iMaxPlayers

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }

public plugin_init()
{
    register_plugin("Portal", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_Portal", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /portal",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Portal menu.")
    register_clcmd("say_team /portal",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Portal menu.")
    register_concmd("portal_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("Portal.txt")

    g_iFwdTouch = RegisterHam(Ham_Touch, "env_sprite", "fwdTouch")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisablePortal()

    portalInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aPortal = ArrayCreate(PORTAL)
    g_aPortalConfig = ArrayCreate(PORTAL)
    g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aPortal)
    ArrayDestroy(g_aPortalConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    portalSound(id, SOUND_MENU_NAV)
    portalMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    portalReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        for ( new id = 1; id <= g_iMaxPlayers; id ++ )
            if ( is_user_connected(id) )
                UpdateData(id)

        ArrayClear(g_aPortalConfig)
        ArrayClear(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT])
        ArrayClear(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT])
        g_iPortalConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/Portal.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        ePortal[PORTAL], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iPortalConfig )
                            ArrayPushArray(g_aPortalConfig, ePortal)

                        copy(ePortal[PORTAL_NAME], charsmax(ePortal[PORTAL_NAME]), szData)
                        copy(ePortal[PORTAL_MODEL], charsmax(ePortal[PORTAL_MODEL]), g_eSettings[SETTING_DEFAULT_MODEL])
                        copy(ePortal[PORTAL_SPRITE], charsmax(ePortal[PORTAL_SPRITE]), g_eSettings[SETTING_DEFAULT_SPRITE])
                        ePortal[PORTAL_FLAGS]                   = g_eSettings[SETTING_DEFAULT_FLAGS]
                        ePortal[PORTAL_TEAM]                    = g_eSettings[SETTING_DEFAULT_TEAM]
                        ePortal[PORTAL_SPRITE_FRAMERATE]        = g_eSettings[SETTING_DEFAULT_SPRITE_FRAMERATE]
                        ePortal[PORTAL_SPRITE_SCALE]            = g_eSettings[SETTING_DEFAULT_SPRITE_SCALE]
                        ePortal[PORTAL_SPRITE_ALPHA]            = g_eSettings[SETTING_DEFAULT_SPRITE_ALPHA]
                        ePortal[PORTAL_SPRITE_COLOR][0]         = g_eSettings[SETTING_DEFAULT_SPRITE_COLOR][0]
                        ePortal[PORTAL_SPRITE_COLOR][1]         = g_eSettings[SETTING_DEFAULT_SPRITE_COLOR][1]
                        ePortal[PORTAL_SPRITE_COLOR][2]         = g_eSettings[SETTING_DEFAULT_SPRITE_COLOR][2]
                        ePortal[PORTAL_DLIGHT_RADIUS]           = g_eSettings[SETTING_DEFAULT_DLIGHT_RADIUS]
                        ePortal[PORTAL_DLIGHT_COLOR][0]         = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][0]
                        ePortal[PORTAL_DLIGHT_COLOR][1]         = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][1]
                        ePortal[PORTAL_DLIGHT_COLOR][2]         = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][2]
                        ePortal[PORTAL_COOLDOWN][0]             = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        ePortal[PORTAL_COOLDOWN][1]             = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]
                        ePortal[PORTAL_SOUND_AMBIENT]           = ArrayClone(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT])
                        ePortal[PORTAL_SOUND_TELEPORT]          = ArrayClone(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT])

                        iSection = SECTION_PORTAL
                        g_iPortalConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPRITE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPRITE], charsmax(g_eSettings[SETTING_DEFAULT_SPRITE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_AMBIENT") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_TELEPORT") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPRITE_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPRITE_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_SPRITE_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPRITE_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPRITE_OFFSET], charsmax(g_eSettings[SETTING_DEFAULT_SPRITE_OFFSET]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPRITE_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPRITE_SCALE], charsmax(g_eSettings[SETTING_DEFAULT_SPRITE_SCALE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPRITE_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPRITE_COLOR], charsmax(g_eSettings[SETTING_DEFAULT_SPRITE_COLOR]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPRITE_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPRITE_ALPHA], charsmax(g_eSettings[SETTING_DEFAULT_SPRITE_ALPHA]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DLIGHT_RADIUS") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DLIGHT_RADIUS], charsmax(g_eSettings[SETTING_DEFAULT_DLIGHT_RADIUS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DLIGHT_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR], charsmax(g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DLIGHT_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DLIGHT_LIFE], charsmax(g_eSettings[SETTING_DEFAULT_DLIGHT_LIFE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_RANDOM_X") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_RANDOM_X], charsmax(g_eSettings[SETTING_RANDOM_X]))
                        else if ( equali(szKey, "SETTING_RANDOM_Y") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_RANDOM_Y], charsmax(g_eSettings[SETTING_RANDOM_Y]))
                        else if ( equali(szKey, "SETTING_RANDOM_Z") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_RANDOM_Z], charsmax(g_eSettings[SETTING_RANDOM_Z]))
                        else if ( equali(szKey, "SETTING_STOP_VELOCITY_ON_TELEPORT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_STOP_VELOCITY_ON_TELEPORT], charsmax(g_eSettings[SETTING_STOP_VELOCITY_ON_TELEPORT]))
                        else if ( equali(szKey, "SETTING_KILL_ON_DESTINATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_KILL_ON_DESTINATION], charsmax(g_eSettings[SETTING_KILL_ON_DESTINATION]))
                        else if ( equali(szKey, "SETTING_KILL_ON_DESTINATION_WORLD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_KILL_ON_DESTINATION_WORLD], charsmax(g_eSettings[SETTING_KILL_ON_DESTINATION_WORLD]))
                        else if ( equali(szKey, "SETTING_MINS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS], charsmax(g_eSettings[SETTING_MINS]))
                        else if ( equali(szKey, "SETTING_MAXS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS], charsmax(g_eSettings[SETTING_MAXS]))
                        else if ( equali(szKey, "SETTING_SPRITE_MINS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_SPRITE_MINS], charsmax(g_eSettings[SETTING_SPRITE_MINS]))
                        else if ( equali(szKey, "SETTING_SPRITE_MAXS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_SPRITE_MAXS], charsmax(g_eSettings[SETTING_SPRITE_MAXS]))
                        else if ( equali(szKey, "SETTING_PORTAL_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_PORTAL_LOAD], charsmax(g_eSettings[SETTING_PORTAL_LOAD]))
                        else if ( equali(szKey, "SETTING_PORTAL_CHECK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_PORTAL_CHECK], charsmax(g_eSettings[SETTING_PORTAL_CHECK]))
                        else if ( equali(szKey, "SETTING_PORTAL_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_PORTAL_TASK], charsmax(g_eSettings[SETTING_PORTAL_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                    }
                    case SECTION_PORTAL:
                    {
                        if ( equali(szKey, "PORTAL_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), ePortal[PORTAL_MODEL], charsmax(ePortal[PORTAL_MODEL]))
                        else if ( equali(szKey, "PORTAL_SPRITE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), ePortal[PORTAL_SPRITE], charsmax(ePortal[PORTAL_SPRITE]))
                        else if ( equali(szKey, "PORTAL_SOUND_AMBIENT") )
                        {
                            if ( !(ePortal[PORTAL_FLAGS] & FLAG_SOUND_AMBIENT) )
                            {
                                ArrayClear(ePortal[PORTAL_SOUND_AMBIENT])
                                ePortal[PORTAL_FLAGS] |= FLAG_SOUND_AMBIENT
                            }

                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), ePortal[PORTAL_SOUND_AMBIENT], charsmax(ePortal[PORTAL_SOUND_AMBIENT]))
                        }
                        else if ( equali(szKey, "PORTAL_SOUND_TELEPORT") )
                        {
                            if ( !(ePortal[PORTAL_FLAGS] & FLAG_SOUND_TELEPORT) )
                            {
                                ArrayClear(ePortal[PORTAL_SOUND_TELEPORT])
                                ePortal[PORTAL_FLAGS] |= FLAG_SOUND_TELEPORT
                            }

                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), ePortal[PORTAL_SOUND_TELEPORT], charsmax(ePortal[PORTAL_SOUND_TELEPORT]))
                        }
                        else if ( equali(szKey, "PORTAL_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), ePortal[PORTAL_FLAGS], charsmax(ePortal[PORTAL_FLAGS]))
                        else if ( equali(szKey, "PORTAL_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), ePortal[PORTAL_TEAM], charsmax(ePortal[PORTAL_TEAM]))
                        else if ( equali(szKey, "PORTAL_SPRITE_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), ePortal[PORTAL_SPRITE_FRAMERATE], charsmax(ePortal[PORTAL_SPRITE_FRAMERATE]))
                        else if ( equali(szKey, "PORTAL_SPRITE_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), ePortal[PORTAL_SPRITE_SCALE], charsmax(ePortal[PORTAL_SPRITE_SCALE]))
                        else if ( equali(szKey, "PORTAL_SPRITE_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), ePortal[PORTAL_SPRITE_COLOR], charsmax(ePortal[PORTAL_SPRITE_COLOR]))
                        else if ( equali(szKey, "PORTAL_SPRITE_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), ePortal[PORTAL_SPRITE_ALPHA], charsmax(ePortal[PORTAL_SPRITE_ALPHA]))
                        else if ( equali(szKey, "PORTAL_DLIGHT_RADIUS") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), ePortal[PORTAL_DLIGHT_RADIUS], charsmax(ePortal[PORTAL_DLIGHT_RADIUS]))
                        else if ( equali(szKey, "PORTAL_DLIGHT_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), ePortal[PORTAL_DLIGHT_COLOR], charsmax(ePortal[PORTAL_DLIGHT_COLOR]))
                        else if ( equali(szKey, "PORTAL_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), ePortal[PORTAL_COOLDOWN], charsmax(ePortal[PORTAL_COOLDOWN]))
                    }
                }
            }
        }
    }

    if ( g_iPortalConfig )
        ArrayPushArray(g_aPortalConfig, ePortal)
    else
        set_fail_state("No Portals were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public client_disconnected(id)
{
    new ePortal[PORTAL], iItem
    if ( g_ePlayerData[id][PDATA_PORTAL_GHOST]
    && (iItem = portalGet(ePortal, g_ePlayerData[id][PDATA_PORTAL_GHOST])) != -1 )
    {
        portalKill(ePortal)
        portalRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_PORTAL_GHOST]  = 0
    g_ePlayerData[id][PDATA_PORTAL_MENU]   = 0
}

public UpdateData(id)
{
    g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]
}

stock portalInit()
{
    if ( g_eSettings[SETTING_PORTAL_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock portalTerminate()
{
    new ePortal[PORTAL]
    for ( new i = 0; i < g_iPortal; i ++ )
    {
        ArrayGetArray(g_aPortal, i, ePortal)
        ePortal[PORTAL_FLAGS] &= ~FLAG_PLAYING
        if ( !(ePortal[PORTAL_FLAGS] & FLAG_PENDING) )
        {
            ArraySetArray(g_aPortal, i, ePortal)
            continue
        }

        ePortal[PORTAL_FLAGS] |= FLAG_ACTIVE
        ePortal[PORTAL_FLAGS] &= ~FLAG_PENDING
        ArraySetArray(g_aPortal, i, ePortal)
    }
}

stock portalMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "PORTAL_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:         { menuRoot(id, iMenu); }
        case MENU_CREATE:       { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "PORTAL_ROOT_CREATE"); }
        case MENU_EDIT:         { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "PORTAL_ROOT_EDIT"); }
        case MENU_REMOVE:       { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "PORTAL_ROOT_REMOVE"); }
        case MENU_SHOW:         { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "PORTAL_ROOT_SHOW"); }
        case MENU_STATUS:       { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "PORTAL_ROOT_STATUS"); }
        case MENU_ROTATE:       { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "PORTAL_ROOT_ROTATE"); }
        case MENU_DESTINATION:  { menuDestination(id, iMenu);   format(szData, charsmax(szData), "%s^n%L", szData, id, "PORTAL_ROOT_DESTINATION"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "PORTAL_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROOT_NOCLIP", id, get_user_noclip(id) ? "PORTAL_ON" : "PORTAL_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROOT_GODMODE", id, get_user_godmode(id) ? "PORTAL_ON" : "PORTAL_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iPortal >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_LIMIT", MAX_ENT)

                portalSound(id, SOUND_MENU_REMOVE)
                portalMenu(id, MENU_ROOT)
            }
            else
            {
                portalSound(id, SOUND_MENU_NAV)
                portalMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iPortal )
            {
                client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_NO_PORTAL")

                portalSound(id, SOUND_MENU_REMOVE)
                portalMenu(id, MENU_ROOT)
            }
            else
            {
                portalSound(id, SOUND_MENU_NAV)
                portalMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iPortal )
            {
                client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_NO_PORTAL")

                portalSound(id, SOUND_MENU_REMOVE)
                portalMenu(id, MENU_ROOT)
            }
            else
            {
                portalSound(id, SOUND_MENU_REMOVE)
                portalMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            portalNoClip(id)
        }
        case ROOT_GODMODE:
        {
            portalGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new ePortal[PORTAL], szItem[64]
    for ( new i = 0; i < g_iPortalConfig; i ++ )
    {
        ArrayGetArray(g_aPortalConfig, i, ePortal)

        copy(szItem, charsmax(szItem), ePortal[PORTAL_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        portalSound(id, SOUND_MENU_NAV)
        portalMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    portalCreate(id, item)
    portalSound(id, SOUND_MENU_NAV)
    portalMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], ePortal[PORTAL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_REMOVE_CURRENT", ePortal[PORTAL_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    portalSelect(ePortal, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)
}

public menuHandlerRemove(id, menu, item)
{
    new ePortal[PORTAL]
    ArrayGetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        portalSelect(ePortal, ePortal[PORTAL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_PORTAL_MENU] >= g_iPortal - 1 )
                g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_PORTAL_MENU] ++

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_PORTAL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_PORTAL_MENU] = g_iPortal - 1
            else
                g_ePlayerData[id][PDATA_PORTAL_MENU] --

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            ePortal[PORTAL_FLAGS] &= ~FLAG_ACTIVE
            portalSetState(ePortal)
            portalKill(ePortal)
            portalRemove(g_ePlayerData[id][PDATA_PORTAL_MENU])

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_REMOVE_CURRENT", ePortal[PORTAL_NAME])
            g_ePlayerData[id][PDATA_PORTAL_MENU] = 0

            portalSound(id, g_iPortal > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            portalMenu(id, g_iPortal > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iPortal )
            {
                ArrayGetArray(g_aPortal, 0, ePortal)
                ePortal[PORTAL_FLAGS] &= ~FLAG_ACTIVE

                portalSetState(ePortal)
                portalKill(ePortal)
                portalRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_PORTAL_MENU] = 0

            portalSound(id, SOUND_MENU_ALERT)
            portalMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                portalSound(id, SOUND_MENU_NAV)
                portalMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], ePortal[PORTAL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_SHOW_CURRENT",
    ePortal[PORTAL_FLAGS] & FLAG_SHOW ? "\y" : "\r", ePortal[PORTAL_NAME], id, ePortal[PORTAL_FLAGS] & FLAG_SHOW ? "PORTAL_SHOWN" : "PORTAL_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    portalSelect(ePortal, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)
}

public menuHandlerShow(id, menu, item)
{
    new ePortal[PORTAL]
    ArrayGetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        portalSelect(ePortal, ePortal[PORTAL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_PORTAL_MENU] >= g_iPortal - 1 )
                g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_PORTAL_MENU] ++

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_PORTAL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_PORTAL_MENU] = g_iPortal - 1
            else
                g_ePlayerData[id][PDATA_PORTAL_MENU] --

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            ePortal[PORTAL_FLAGS] ^= FLAG_SHOW
            portalSetState(ePortal)

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_SHOW_CURRENT",
            ePortal[PORTAL_NAME], id, ePortal[PORTAL_FLAGS] & FLAG_SHOW ? "PORTAL_CHAT_SHOWN" : "PORTAL_CHAT_HIDDEN")
            ArraySetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iPortal; i ++ )
            {
                ArrayGetArray(g_aPortal, i, ePortal)
                ePortal[PORTAL_FLAGS] |= FLAG_SHOW
                portalSetState(ePortal)

                ArraySetArray(g_aPortal, i, ePortal)
            }

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_SHOW_ALL_SHOWN")
            portalSound(id, SOUND_MENU_ALERT)
            portalMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iPortal; i ++ )
            {
                ArrayGetArray(g_aPortal, i, ePortal)
                ePortal[PORTAL_FLAGS] &= ~FLAG_SHOW
                portalSetState(ePortal)

                ArraySetArray(g_aPortal, i, ePortal)
            }

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_SHOW_ALL_HIDDEN")
            portalSound(id, SOUND_MENU_ALERT)
            portalMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                portalSound(id, SOUND_MENU_NAV)
                portalMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], ePortal[PORTAL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_STATUS_CURRENT",
    ePortal[PORTAL_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", ePortal[PORTAL_NAME], id, ePortal[PORTAL_FLAGS] & FLAG_ACTIVE ? "PORTAL_ENABLED" : "PORTAL_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    portalSelect(ePortal, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)
}

public menuHandlerStatus(id, menu, item)
{
    new ePortal[PORTAL]
    ArrayGetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        portalSelect(ePortal, ePortal[PORTAL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_PORTAL_MENU] >= g_iPortal - 1 )
                g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_PORTAL_MENU] ++

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_PORTAL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_PORTAL_MENU] = g_iPortal - 1
            else
                g_ePlayerData[id][PDATA_PORTAL_MENU] --

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            ePortal[PORTAL_FLAGS] ^= FLAG_ACTIVE
            portalSetState(ePortal)

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_STATUS_CURRENT",
            ePortal[PORTAL_NAME], id, ePortal[PORTAL_FLAGS] & FLAG_ACTIVE ? "PORTAL_CHAT_ENABLED" : "PORTAL_CHAT_DISABLED")
            ArraySetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iPortal; i ++ )
            {
                ArrayGetArray(g_aPortal, i, ePortal)
                ePortal[PORTAL_FLAGS] |= FLAG_ACTIVE
                portalSetState(ePortal)

                ArraySetArray(g_aPortal, i, ePortal)
            }

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_STATUS_ALL_ENABLED")
            portalSound(id, SOUND_MENU_ALERT)
            portalMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iPortal; i ++ )
            {
                ArrayGetArray(g_aPortal, i, ePortal)
                ePortal[PORTAL_FLAGS] &= ~FLAG_ACTIVE
                portalSetState(ePortal)

                ArraySetArray(g_aPortal, i, ePortal)
            }

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_STATUS_ALL_DISABLED")
            portalSound(id, SOUND_MENU_ALERT)
            portalMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                portalSound(id, SOUND_MENU_NAV)
                portalMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_PORTAL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], ePortal[PORTAL]
    if ( portalGet(ePortal, g_ePlayerData[id][PDATA_PORTAL_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROTATE_GROUND",
    id, ePortal[PORTAL_FLAGS] & FLAG_GROUND ? "PORTAL_ON" : "PORTAL_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new ePortal[PORTAL], iItem
    if ( (iItem = portalGet(ePortal, g_ePlayerData[id][PDATA_PORTAL_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(ePortal[PORTAL_ID], pev_angles, ePortal[PORTAL_ANGLES])
            ePortal[PORTAL_ANGLES][1] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( ePortal[PORTAL_ANGLES][1] < -180.0 ) ePortal[PORTAL_ANGLES][1] += 360.0

            set_pev(ePortal[PORTAL_ID], pev_angles, ePortal[PORTAL_ANGLES])
            ArraySetArray(g_aPortal, iItem, ePortal)

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(ePortal[PORTAL_ID], pev_angles, ePortal[PORTAL_ANGLES])
            ePortal[PORTAL_ANGLES][1] += g_eSettings[SETTING_ROTATION_STEP]
            if ( ePortal[PORTAL_ANGLES][1] > 180.0 ) ePortal[PORTAL_ANGLES][1] -= 360.0

            set_pev(ePortal[PORTAL_ID], pev_angles, ePortal[PORTAL_ANGLES])
            ArraySetArray(g_aPortal, iItem, ePortal)

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            ePortal[PORTAL_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aPortal, iItem, ePortal)

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            portalTrace(ePortal, id)
            ePortal[PORTAL_FLAGS] |= FLAG_SHOW
            ePortal[PORTAL_ANGLES][0] = -ePortal[PORTAL_ANGLES][0]
            if ( ePortal[PORTAL_FLAGS] & FLAG_RANDOM )
            {
                DisableAction(id)
                set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
                ePortal[PORTAL_FLAGS] |= FLAG_ACTIVE
                ePortal[PORTAL_FLAGS] &= ~FLAG_GHOST
                g_ePlayerData[id][PDATA_PORTAL_GHOST] = 0

                portalSetSize(ePortal)
                portalSetState(ePortal)
                client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_CREATE_NEW", ePortal[PORTAL_NAME])
            }
            else
            {
                portalCreateSprite(ePortal, SPRITE_DEST)
                portalSetSize(ePortal)
            }

            ArraySetArray(g_aPortal, iItem, ePortal)
            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, ePortal[PORTAL_FLAGS] & FLAG_RANDOM ? MENU_CREATE : MENU_DESTINATION)
        }
        case MENU_EXIT:
        {
            portalKill(ePortal)
            portalRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_PORTAL_GHOST] = 0

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_CREATE)
        }
        default:
        {
            portalKill(ePortal)
            portalRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_PORTAL_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuDestination(id, iMenu)
{
    new szItem[64], ePortal[PORTAL]
    if ( portalGet(ePortal, g_ePlayerData[id][PDATA_PORTAL_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "PORTAL_DESTINATION_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerDestination(id, menu, item)
{
    new ePortal[PORTAL], iItem
    if ( (iItem = portalGet(ePortal, g_ePlayerData[id][PDATA_PORTAL_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch ( item )
    {
        case DESTINATION_PLACE:
        {
            DisableAction(id)
            portalTrace(ePortal, id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_PORTAL_GHOST] = 0
            ePortal[PORTAL_FLAGS] |= FLAG_ACTIVE
            ePortal[PORTAL_FLAGS] &= ~(FLAG_GHOST | FLAG_LOCK)
            pev(ePortal[PORTAL_SPRITE_DESTINATION], pev_origin, ePortal[PORTAL_ORIGIN_DESTINATION])
            set_pev(ePortal[PORTAL_SPRITE_DESTINATION], pev_movetype, MOVETYPE_NONE)

            portalSetState(ePortal)
            ArraySetArray(g_aPortal, iItem, ePortal)

            client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_CREATE_NEW", ePortal[PORTAL_NAME])
            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            portalKill(ePortal)
            portalRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_PORTAL_GHOST] = 0

            portalSound(id, SOUND_MENU_NAV)
            portalMenu(id, MENU_CREATE)
        }
        default:
        {
            portalKill(ePortal)
            portalRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_PORTAL_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public portalTask()
{
    new ePortal[PORTAL], Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iPortal; i ++ )
    {
        ArrayGetArray(g_aPortal, i, ePortal)

        if ( ePortal[PORTAL_FLAGS] & FLAG_SHOW )
        {
            if ( ePortal[PORTAL_FLAGS] & FLAG_ACTIVE )
            {
                if ( ePortal[PORTAL_FLAGS] & FLAG_DLIGHT )
                    portalDLight(ePortal)
            }
            else
            {
                if ( ePortal[PORTAL_NEXT_COOLDOWN] > 0.0
                && fCurrentTime >= ePortal[PORTAL_NEXT_COOLDOWN] )
                {
                    ePortal[PORTAL_FLAGS] |= FLAG_ACTIVE
                    ePortal[PORTAL_FLAGS] &= ~FLAG_PENDING
                    portalSetState(ePortal)
                    ArraySetArray(g_aPortal, i, ePortal)
                }
            }
        }
    }
}

stock portalCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new ePortal[PORTAL]
    ArrayGetArray(g_aPortalConfig, iItem, ePortal)
    ePortal[PORTAL_ID] = iEnt
    ePortal[PORTAL_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_PORTAL_GHOST] = ePortal[PORTAL_ID]
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        ePortal[PORTAL_FLAGS] |= FLAG_GHOST
    }

    portalSelect(ePortal, TARGET_GHOST, false)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, PORTAL_KEY)
    set_pev(iEnt, PORTAL_ARRAY_ITEM, g_iPortal)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, ePortal[PORTAL_MODEL])

    ArrayPushArray(g_aPortal, ePortal)
    if ( ++ g_iPortal == 1 )
    {
        set_task(g_eSettings[SETTING_PORTAL_TASK], "portalTask", PORTAL_KEY, .flags = "b")
        EnablePortal()
    }
}

stock portalCreateSprite(ePortal[PORTAL], iSpriteType)
{
    new iEnt = cs_create_entity("env_sprite")
    if ( !pev_valid(iEnt) )
        return

    new szCN[32], Float:fOrigin[3]
    if ( iSpriteType == SPRITE_BASE )      { ePortal[PORTAL_SPRITE_BASE] = iEnt;        formatex(szCN, charsmax(szCN), "%s_sprite_base", g_szCN); }
    else if ( iSpriteType == SPRITE_DEST ) { ePortal[PORTAL_SPRITE_DESTINATION] = iEnt; formatex(szCN, charsmax(szCN), "%s_sprite_dest", g_szCN);   ePortal[PORTAL_FLAGS] |= FLAG_LOCK; }
    set_pev(iEnt, PORTAL_OWNER, ePortal[PORTAL_ID])
    set_pev(iEnt, pev_classname, szCN)
    set_pev(iEnt, pev_framerate, ePortal[PORTAL_SPRITE_FRAMERATE])
    set_pev(iEnt, pev_spawnflags, SF_SPRITE_STARTON)
    engfunc(EngFunc_SetModel, iEnt, ePortal[PORTAL_SPRITE])
    dllfunc(DLLFunc_Spawn, iEnt)
    if ( iSpriteType == SPRITE_BASE )
    {
        set_pev(iEnt, pev_solid, SOLID_TRIGGER)
        set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
    }
    else if ( iSpriteType == SPRITE_DEST )
    {
        set_pev(iEnt, pev_solid, SOLID_NOT)
        set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    }

    engfunc(EngFunc_AngleVectors, ePortal[PORTAL_ANGLES], NULL_VECTOR, NULL_VECTOR, fOrigin)
    xs_vec_mul_scalar(fOrigin, g_eSettings[SETTING_DEFAULT_SPRITE_OFFSET], fOrigin)
    xs_vec_add(fOrigin, ePortal[PORTAL_ORIGIN_BASE], fOrigin)
    engfunc(EngFunc_SetOrigin, iEnt, fOrigin)

    set_pev(iEnt, pev_scale, ePortal[PORTAL_SPRITE_SCALE])
    set_ent_rendering(iEnt, kRenderFxNone, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, ePortal[PORTAL_SPRITE_ALPHA])
}

public portalRemove(iItem)
{
    new ePortal[PORTAL]
    ArrayDeleteItem(g_aPortal, iItem)
    if ( -- g_iPortal == 0 )
    {
        remove_task(PORTAL_KEY)
        DisablePortal()
    }

    for ( new i = iItem; i < g_iPortal; i ++ )
    {
        ArrayGetArray(g_aPortal, i, ePortal)
        set_pev(ePortal[PORTAL_ID], PORTAL_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new ePortal[PORTAL],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Portal.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    portalTerminate()
    for ( new i = 0; i < g_iPortal; i ++ )
    {
        ArrayGetArray(g_aPortal, i, ePortal)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", ePortal[PORTAL_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", ePortal[PORTAL_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        ePortal[PORTAL_ORIGIN_BASE][0], ePortal[PORTAL_ORIGIN_BASE][1], ePortal[PORTAL_ORIGIN_BASE][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        ePortal[PORTAL_ANGLES][0], ePortal[PORTAL_ANGLES][1], ePortal[PORTAL_ANGLES][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "destination = %.2f %.2f %.2f^n",
        ePortal[PORTAL_ORIGIN_DESTINATION][0], ePortal[PORTAL_ORIGIN_DESTINATION][1], ePortal[PORTAL_ORIGIN_DESTINATION][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "PORTAL_CHAT_TAG", id, "PORTAL_CHAT_SAVE", szFile)
    fclose(iFile)

    portalSound(id, SOUND_MENU_NAV)
    portalMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], Float:fDestination[3],
        iItem, iFlags, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Portal.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataPortal(iItem, iFlags, fOrigin, fAngles, fDestination, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "destination") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fDestination[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fDestination[1] = str_to_float(szKey)
                fDestination[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataPortal(iItem, iFlags, fOrigin, fAngles, fDestination, iCount)

    fclose(iFile)
}

stock LoadDataPortal(iItem, iFlags, Float:fOrigin[3], Float:fAngles[3], Float:fDestination[3], iCount)
{
    new ePortal[PORTAL]
    portalCreate(0, iItem)
    ArrayGetArray(g_aPortal, iCount, ePortal)

    ePortal[PORTAL_FLAGS] = iFlags
    xs_vec_copy(fOrigin, ePortal[PORTAL_ORIGIN_BASE])
    xs_vec_copy(fAngles, ePortal[PORTAL_ANGLES])
    xs_vec_copy(fDestination, ePortal[PORTAL_ORIGIN_DESTINATION])

    portalSetBox(ePortal)
    portalSetSize(ePortal)
    portalSetState(ePortal)
    ArraySetArray(g_aPortal, iCount, ePortal)
}

public portalNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    portalSound(id, SOUND_MENU_NAV)
    portalMenu(id, MENU_ROOT)
}

public portalGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    portalSound(id, SOUND_MENU_NAV)
    portalMenu(id, MENU_ROOT)
}

public fwdTouch(iEnt, iOther)
{
    if ( !isPortal(pev(iEnt, PORTAL_OWNER))
    || pev(iOther, pev_solid) == SOLID_NOT
    || pev(iOther, pev_movetype) == MOVETYPE_NONE
    || pev(iOther, pev_movetype) == MOVETYPE_FOLLOW )
        return HAM_IGNORED

    new ePortal[PORTAL], iItem
    if ( (iItem = portalGet(ePortal, pev(iEnt, PORTAL_OWNER))) == -1
    || !(ePortal[PORTAL_FLAGS] & FLAG_ACTIVE)
    || (ePortal[PORTAL_FLAGS] & FLAG_PLAYERS_ONLY && !is_user_alive(iOther))
    || (is_user_alive(iOther) && !(CsTeams:ePortal[PORTAL_TEAM] & cs_get_user_team(iOther))) )
        return HAM_IGNORED

    new szSound[MAX_RESOURCE_PATH_LENGTH], iTarget, iHit
    iTarget = g_eSettings[SETTING_KILL_ON_DESTINATION_WORLD] ? ePortal[PORTAL_ID] : iOther
    ArrayGetString(ePortal[PORTAL_SOUND_TELEPORT], random(ArraySize(ePortal[PORTAL_SOUND_TELEPORT])), szSound, charsmax(szSound))
    if ( ePortal[PORTAL_FLAGS] & FLAG_RANDOM )
    {
        new Float:fOrigin[3]
        for ( new i = 0; i < RANDOM_MAX; i ++ )
        {
            xs_vec_copy(ePortal[PORTAL_ORIGIN_BASE], fOrigin)
            fOrigin[0] += random_float(g_eSettings[SETTING_RANDOM_X][0], g_eSettings[SETTING_RANDOM_X][1])
            fOrigin[1] += random_float(g_eSettings[SETTING_RANDOM_Y][0], g_eSettings[SETTING_RANDOM_Y][1])
            fOrigin[2] += random_float(g_eSettings[SETTING_RANDOM_Z][0], g_eSettings[SETTING_RANDOM_Z][1])
            engfunc(EngFunc_TraceHull, fOrigin, fOrigin, DONT_IGNORE_MONSTERS, HULL_HUMAN, iOther, 0)
            if ( get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) )
                continue

            iHit = get_tr2(0, TR_pHit)
            if ( g_eSettings[SETTING_STOP_VELOCITY_ON_TELEPORT] )
                set_pev(iOther, pev_velocity, NULL_VECTOR)

            if ( g_eSettings[SETTING_KILL_ON_DESTINATION]
            && pev_valid(iHit)
            && pev(iHit, pev_takedamage) != DAMAGE_NO )
                ExecuteHamB(Ham_TakeDamage, iHit, iTarget, iTarget, PORTAL_DEATH_PENALTY, DMG_ALWAYSGIB)

            if ( ePortal[PORTAL_FLAGS] & FLAG_COOLDOWN )
            {
                ePortal[PORTAL_FLAGS] &= ~FLAG_ACTIVE
                ePortal[PORTAL_FLAGS] |= FLAG_PENDING
                ePortal[PORTAL_NEXT_COOLDOWN] = get_gametime() + random_float(ePortal[PORTAL_COOLDOWN][0], ePortal[PORTAL_COOLDOWN][1])
                portalSetState(ePortal)
            }

            engfunc(EngFunc_SetOrigin, iOther, fOrigin)
            engfunc(EngFunc_EmitSound, iOther, CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
            ArraySetArray(g_aPortal, iItem, ePortal)
            break
        }
    }
    else
    {
        if ( g_eSettings[SETTING_STOP_VELOCITY_ON_TELEPORT] )
            set_pev(iOther, pev_velocity, NULL_VECTOR)

        if ( g_eSettings[SETTING_KILL_ON_DESTINATION] )
        {
            engfunc(EngFunc_TraceHull, ePortal[PORTAL_ORIGIN_DESTINATION], ePortal[PORTAL_ORIGIN_DESTINATION], DONT_IGNORE_MONSTERS, HULL_HUMAN, 0, 0)
            iHit = get_tr2(0, TR_pHit)

            if ( pev_valid(iHit)
            && pev(iHit, pev_takedamage) != DAMAGE_NO )
                ExecuteHamB(Ham_TakeDamage, iHit, iTarget, iTarget, PORTAL_DEATH_PENALTY, DMG_ALWAYSGIB)
        }

        if ( ePortal[PORTAL_FLAGS] & FLAG_COOLDOWN )
        {
            ePortal[PORTAL_FLAGS] &= ~FLAG_ACTIVE
            ePortal[PORTAL_FLAGS] |= FLAG_PENDING
            ePortal[PORTAL_NEXT_COOLDOWN] = get_gametime() + random_float(ePortal[PORTAL_COOLDOWN][0], ePortal[PORTAL_COOLDOWN][1])
            portalSetState(ePortal)
        }

        engfunc(EngFunc_SetOrigin, iOther, ePortal[PORTAL_ORIGIN_DESTINATION])
        engfunc(EngFunc_EmitAmbientSound, iOther, CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
        ArraySetArray(g_aPortal, iItem, ePortal)
    }

    return HAM_IGNORED
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static ePortal[PORTAL], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( portalGet(ePortal, g_ePlayerData[id][PDATA_PORTAL_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_PORTAL_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            portalTrace(ePortal, id)
        }
        else if ( g_ePlayerData[id][PDATA_PORTAL_ACTION] )
        {
            portalCheck(id)
        }
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_PORTAL_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_PORTAL_GHOST] )
    {
        new ePortal[PORTAL], iItem
        if ( (iItem = portalGet(ePortal, g_ePlayerData[id][PDATA_PORTAL_GHOST])) != -1 )
        {
            portalKill(ePortal)
            portalRemove(iItem)
        }

        g_ePlayerData[id][PDATA_PORTAL_GHOST] = 0
    }
}

stock portalTrace(ePortal[PORTAL], id)
{
    new Float:fVec1[3], Float:fVec2[3]

    pev(id, pev_origin, fVec1)
    if ( ePortal[PORTAL_FLAGS] & FLAG_LOCK )
    {
        pev(id, pev_view_ofs, fVec2)
        xs_vec_add(fVec1, fVec2, fVec1)
    }
    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    xs_vec_mul_scalar(fVec2, g_ePlayerData[id][PDATA_OFFSET], fVec2)
    xs_vec_add(fVec2, fVec1, fVec2)
    engfunc(EngFunc_TraceLine, fVec1, fVec2, DONT_IGNORE_MONSTERS, id, 0)

    if ( ePortal[PORTAL_FLAGS] & FLAG_LOCK )
    {
        get_tr2(0, TR_vecEndPos, fVec1)
        set_pev(ePortal[PORTAL_SPRITE_DESTINATION], pev_origin, fVec1)
    }
    else
    {
        get_tr2(0, TR_vecEndPos, ePortal[PORTAL_ORIGIN_BASE])
        portalSetBox(ePortal)
        portalSetOffset(ePortal)
        set_pev(ePortal[PORTAL_ID], pev_origin, ePortal[PORTAL_ORIGIN_BASE])
    }
}

stock portalCheck(id)
{
    new ePortal[PORTAL], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_PORTAL_CHECK]
    for ( new i = 0; i < g_iPortal; i ++ )
    {
        ArrayGetArray(g_aPortal, i, ePortal)
        xs_vec_sub(ePortal[PORTAL_ORIGIN_BASE], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(ePortal[PORTAL_ID], pev_absmin, fMins)
        pev(ePortal[PORTAL_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_PORTAL_MENU] != iBest )
    {
        ArrayGetArray(g_aPortal, g_ePlayerData[id][PDATA_PORTAL_MENU], ePortal)
        portalSelect(ePortal, ePortal[PORTAL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_PORTAL_MENU] = iBest
        portalMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock portalDLight(ePortal[PORTAL])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, ePortal[PORTAL_ORIGIN_BASE])
    write_byte(TE_DLIGHT)
    write_coord_f(ePortal[PORTAL_ORIGIN_BASE][0])
    write_coord_f(ePortal[PORTAL_ORIGIN_BASE][1])
    write_coord_f(ePortal[PORTAL_ORIGIN_BASE][2])
    write_byte(ePortal[PORTAL_DLIGHT_RADIUS])
    write_byte(ePortal[PORTAL_DLIGHT_COLOR][0])
    write_byte(ePortal[PORTAL_DLIGHT_COLOR][1])
    write_byte(ePortal[PORTAL_DLIGHT_COLOR][2])
    write_byte(g_eSettings[SETTING_DEFAULT_DLIGHT_LIFE])
    write_byte(0)
    message_end()
}

stock portalSetBox(ePortal[PORTAL])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    ePortal[PORTAL_ANGLES][0] = -ePortal[PORTAL_ANGLES][0]
    engfunc(EngFunc_AngleVectors, ePortal[PORTAL_ANGLES], fForward, fRight, fUp)
    xs_vec_copy(g_eSettings[SETTING_MINS], fMins)
    xs_vec_copy(g_eSettings[SETTING_MAXS], fMaxs)

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, ePortal[PORTAL_MINS])
    xs_vec_copy(fMaxs, ePortal[PORTAL_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] + fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] + fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] + fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock portalSetOffset(ePortal[PORTAL])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -ePortal[PORTAL_MINS][0]
    fGaps[1] = ePortal[PORTAL_MAXS][0]
    fGaps[2] = -ePortal[PORTAL_MINS][1]
    fGaps[3] = ePortal[PORTAL_MAXS][1]
    fGaps[4] = -ePortal[PORTAL_MINS][2]
    fGaps[5] = ePortal[PORTAL_MAXS][2]

    if ( ePortal[PORTAL_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(ePortal[PORTAL_ORIGIN_BASE], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, ePortal[PORTAL_ORIGIN_BASE], fVec1, DONT_IGNORE_MONSTERS, ePortal[PORTAL_ID], 0)
        get_tr2(0, TR_vecEndPos, ePortal[PORTAL_ORIGIN_BASE])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, ePortal[PORTAL_ORIGIN_BASE], fVec1)
        engfunc(EngFunc_TraceLine, ePortal[PORTAL_ORIGIN_BASE], fVec1, DONT_IGNORE_MONSTERS, ePortal[PORTAL_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(ePortal[PORTAL_ORIGIN_BASE], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(ePortal[PORTAL_ORIGIN_BASE], fVec1, ePortal[PORTAL_ORIGIN_BASE])
        }
    }
}

stock portalSetSeq(iEnt, Float:fFrameRate, iSequence)
{
    set_pev(iEnt, pev_sequence, iSequence)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFrameRate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock portalSetSize(ePortal[PORTAL])
{
    new Float:fMins[3], Float:fMaxs[3]
    portalSelect(ePortal, TARGET_CLEAR, false)
    engfunc(EngFunc_SetOrigin, ePortal[PORTAL_ID], ePortal[PORTAL_ORIGIN_BASE])
    set_pev(ePortal[PORTAL_ID], pev_angles, ePortal[PORTAL_ANGLES])
    set_pev(ePortal[PORTAL_ID], pev_solid, ePortal[PORTAL_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(ePortal[PORTAL_ID], pev_movetype, MOVETYPE_NONE)

    ePortal[PORTAL_ANGLES][0] = -ePortal[PORTAL_ANGLES][0]
    xs_vec_mul_scalar(g_eSettings[SETTING_SPRITE_MINS], ePortal[PORTAL_SPRITE_SCALE] * 2.5, fMins)
    xs_vec_mul_scalar(g_eSettings[SETTING_SPRITE_MAXS], ePortal[PORTAL_SPRITE_SCALE] * 2.5, fMaxs)
    portalCreateSprite(ePortal, SPRITE_BASE)
    engfunc(EngFunc_SetSize, ePortal[PORTAL_ID], ePortal[PORTAL_MINS], ePortal[PORTAL_MAXS])
    engfunc(EngFunc_SetSize, ePortal[PORTAL_SPRITE_BASE], fMins, fMaxs)
    ArrayGetString(ePortal[PORTAL_SOUND_AMBIENT], random(ArraySize(ePortal[PORTAL_SOUND_AMBIENT])), ePortal[PORTAL_SOUND_AMBIENT_CURRENT], charsmax(ePortal[PORTAL_SOUND_AMBIENT_CURRENT]))
}

stock portalSetState(ePortal[PORTAL])
{
    if ( ePortal[PORTAL_FLAGS] & FLAG_SHOW )
    {
        set_pev(ePortal[PORTAL_ID], pev_solid, SOLID_BBOX)
        set_pev(ePortal[PORTAL_SPRITE_BASE], pev_solid, SOLID_TRIGGER)
        portalSelect(ePortal, TARGET_CLEAR)

        if ( ePortal[PORTAL_FLAGS] & FLAG_SOUND )
        {
            if ( ePortal[PORTAL_FLAGS] & FLAG_ACTIVE )
            {
                if ( !(ePortal[PORTAL_FLAGS] & FLAG_PLAYING) )
                {
                    ePortal[PORTAL_FLAGS] |= FLAG_PLAYING
                    engfunc(EngFunc_EmitAmbientSound, ePortal[PORTAL_ID], CHAN_ITEM, ePortal[PORTAL_SOUND_AMBIENT_CURRENT], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                }
            }
            else
            {
                if ( ePortal[PORTAL_FLAGS] & FLAG_PLAYING )
                {
                    ePortal[PORTAL_FLAGS] &= ~FLAG_PLAYING
                    engfunc(EngFunc_EmitAmbientSound, ePortal[PORTAL_ID], CHAN_ITEM, ePortal[PORTAL_SOUND_AMBIENT_CURRENT], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
                }
            }
        }
    }
    else
    {
        set_pev(ePortal[PORTAL_ID], pev_solid, SOLID_NOT)
        set_pev(ePortal[PORTAL_SPRITE_BASE], pev_solid, SOLID_NOT)
        portalSelect(ePortal, TARGET_HIDE)

        if ( ePortal[PORTAL_FLAGS] & (FLAG_PLAYING | FLAG_SOUND) == (FLAG_PLAYING | FLAG_SOUND) )
        {
            ePortal[PORTAL_FLAGS] &= ~FLAG_PLAYING
            engfunc(EngFunc_EmitAmbientSound, ePortal[PORTAL_ID], CHAN_ITEM, ePortal[PORTAL_SOUND_AMBIENT_CURRENT], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
        }
    }
}

stock portalSelect(ePortal[PORTAL], iAction, bool:bSpriteExists = true)
{
    new iRenderColor[3]
    if ( iAction == TARGET_SELECT )
    {
        if ( ePortal[PORTAL_FLAGS] & FLAG_ACTIVE )  { iRenderColor[0] = g_iColorActive[0];   iRenderColor[1] = g_iColorActive[1];     iRenderColor[2] = g_iColorActive[2]; }
        else                                        { iRenderColor[0] = g_iColorInactive[0]; iRenderColor[1] = g_iColorInactive[1];   iRenderColor[2] = g_iColorInactive[2]; }

        set_ent_rendering(ePortal[PORTAL_ID], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
        set_ent_rendering(ePortal[PORTAL_SPRITE_BASE], kRenderFxGlowShell, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, 64)
        set_ent_rendering(ePortal[PORTAL_SPRITE_DESTINATION], kRenderFxGlowShell, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, 64)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_ent_rendering(ePortal[PORTAL_ID], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, g_eSettings[SETTING_GHOST_ALPHA])

        if ( bSpriteExists )
        {
            set_ent_rendering(ePortal[PORTAL_SPRITE_BASE], kRenderFxNone, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, g_eSettings[SETTING_GHOST_ALPHA])
            set_ent_rendering(ePortal[PORTAL_SPRITE_DESTINATION], kRenderFxNone, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, g_eSettings[SETTING_GHOST_ALPHA])
        }
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_ent_rendering(ePortal[PORTAL_ID], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
        set_ent_rendering(ePortal[PORTAL_SPRITE_BASE], kRenderFxNone, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, 0)
        set_ent_rendering(ePortal[PORTAL_SPRITE_DESTINATION], kRenderFxNone, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, 0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_ent_rendering(ePortal[PORTAL_ID], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)

        if ( bSpriteExists )
        {
            set_ent_rendering(ePortal[PORTAL_SPRITE_BASE], kRenderFxNone, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, ePortal[PORTAL_FLAGS] & FLAG_ACTIVE ? ePortal[PORTAL_SPRITE_ALPHA] : 0)
            set_ent_rendering(ePortal[PORTAL_SPRITE_DESTINATION], kRenderFxNone, ePortal[PORTAL_SPRITE_COLOR][0], ePortal[PORTAL_SPRITE_COLOR][1], ePortal[PORTAL_SPRITE_COLOR][2], kRenderTransAdd, 0)
        }
    }
}

stock portalReset()
{
    new ePortal[PORTAL]
    for ( new i = 0; i < g_iPortal; i ++ )
    {
        ArrayGetArray(g_aPortal, i, ePortal)
        ePortal[PORTAL_NEXT_COOLDOWN] = 0.0
        ArraySetArray(g_aPortal, i, ePortal)
    }
}

stock portalSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}



stock portalGet(ePortal[PORTAL], iEnt)
{
    if ( !isPortal(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, PORTAL_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iPortal )
        return -1

    ArrayGetArray(g_aPortal, iItem, ePortal)
    return iItem
}

stock bool:isPortal(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == PORTAL_KEY
}

stock portalKill(ePortal[PORTAL])
{
    if ( pev_valid(ePortal[PORTAL_ID]) )
        set_pev(ePortal[PORTAL_ID], pev_flags, pev(ePortal[PORTAL_ID], pev_flags) | FL_KILLME)

    if ( pev_valid(ePortal[PORTAL_SPRITE_BASE]) )
        set_pev(ePortal[PORTAL_SPRITE_BASE], pev_flags, pev(ePortal[PORTAL_SPRITE_BASE], pev_flags) | FL_KILLME)

    if ( pev_valid(ePortal[PORTAL_SPRITE_DESTINATION]) )
        set_pev(ePortal[PORTAL_SPRITE_DESTINATION], pev_flags, pev(ePortal[PORTAL_SPRITE_DESTINATION], pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_ARRAY_STRING:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_PORTAL_ACTION] )
    {
        new ePortal[PORTAL]
        for ( new i = 0; i < g_iPortal; i ++ )
        {
            ArrayGetArray(g_aPortal, i, ePortal)
            if ( ePortal[PORTAL_FLAGS] & FLAG_SHOW )
                continue

            portalSelect(ePortal, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_PORTAL_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_PORTAL_ACTION] )
    {
        new ePortal[PORTAL]
        for ( new i = 0; i < g_iPortal; i ++ )
        {
            ArrayGetArray(g_aPortal, i, ePortal)
            if ( ePortal[PORTAL_FLAGS] & FLAG_SHOW )
                continue

            portalSelect(ePortal, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_PORTAL_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock EnablePortal()
{
    EnableHamForward(g_iFwdTouch)
}

stock DisablePortal()
{
    DisableHamForward(g_iFwdTouch)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}