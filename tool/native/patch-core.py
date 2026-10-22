"""Audited AWG 3.1 adapter against core.lock.json; fail on source drift."""
from pathlib import Path
import sys
root = Path(sys.argv[1])
box = root / 'hiddify-sing-box'
# All AWG device, bind and TUN types must use the same v3 module.
for p in list((box/'transport/awg').glob('*.go')) + list((box/'protocol/awg').glob('*.go')):
    s = p.read_text()
    s = s.replace('github.com/amnezia-vpn/amneziawg-go/', 'github.com/amnezia-vpn/amneziawg-go/v3/')
    s = s.replace('/amneziawg-go/v3/v3/', '/amneziawg-go/v3/')
    p.write_text(s)
p = box / 'protocol/awg/h_endpoint_test.go'
s = p.read_text()
s = s.replace('\tt.Skip("BUG: genIpcConfig emits s3=/s4= but the pinned amneziawg-go fork rejects them (invalid UAPI device key: s3)")\n', '')
p.write_text(s)
# Go field, native UAPI key, .conf field name. Ranges stay strings, not integers.
fields = [
 ('HeaderProtectionKey','header_protection_key','HeaderProtectionKey'),
 ('ContentPaddingAddition','content_padding_addition','ContentPaddingAddition'),
 ('RekeyAfterTime','rekey_after_time','RekeyAfterTime'),
 ('RekeyTimeout','rekey_timeout','RekeyTimeout'),
 ('RejectAfterTime','reject_after_time','RejectAfterTime'),
 ('KeepaliveTimeout','keepalive_timeout','KeepaliveTimeout'),
 ('MaxHandshakeAttempts','max_handshake_attempts','MaxHandshakeAttempts'),
]
bools = [('RandomTrailers','random_trailers','RandomTrailers'), ('DisableCookies','disable_cookies','DisableCookies')]
p = box / 'option/awg.go'
s = p.read_text()
if 'HeaderProtectionKey' not in s:
    needle = 'type AwgOptions struct {'
    assert needle in s
    extra = ''.join(f'\n\t{field} string `json:"{key},omitempty"`' for field,key,_ in fields)
    extra += ''.join(f'\n\t{field} bool `json:"{key},omitempty"`' for field,key,_ in bools)
    s = s.replace(needle, needle + extra, 1)
    s = s.replace('return o.Jc != 0', 'return '+ ' || '.join([f'o.{f} != ""' for f,_,_ in fields]+[f'o.{f}' for f,_,_ in bools])+' || o.Jc != 0',1)
    s = s.replace('type AwgPeerOptions struct {', 'type AwgPeerOptions struct {\n\tPersistentKeepalive string `json:"persistent_keepalive,omitempty"`',1)
    p.write_text(s)
p = box / 'protocol/awg/endpoint.go'
s = p.read_text()
if 'awg.HeaderProtectionKey' not in s:
    extra = '''
    if awg.HeaderProtectionKey != "" {
        key, err := base64.StdEncoding.DecodeString(awg.HeaderProtectionKey)
        if err != nil || len(key) != 32 { return "", E.New("invalid AmneziaWG header protection key") }
        s += "\\nheader_protection_key=" + hex.EncodeToString(key)
    }
'''
    extra += ''.join(f'\tif awg.{f} != "" {{ s += "\\n{k}=" + awg.{f} }}\n' for f,k,_ in fields if f != 'HeaderProtectionKey')
    extra += ''.join(f'\tif awg.{f} {{ s += "\\n{k}=true" }}\n' for f,k,_ in bools)
    needle = '\n\tfor _, peer := range opts.Peers {'
    assert needle in s
    s = s.replace(needle, '\n'+extra+needle,1)
    s = s.replace('if peer.PersistentKeepaliveInterval != 0 {', 'if peer.PersistentKeepalive != "" {\n\t\ts += "\\npersistent_keepalive_interval=" + peer.PersistentKeepalive\n\t\t} else if peer.PersistentKeepaliveInterval != 0 {',1)
    p.write_text(s)
p = root / 'ray2sing/ray2sing/awg.go'
s = p.read_text()
# ListenPort is retained even on the older pre-3.1 patch checkpoint.
if 'var listenPort uint16' not in s:
    s = s.replace('func AWGSingboxTxt(content string) (*T.Endpoint, error) {',
                  'func AWGSingboxTxt(content string) (*T.Endpoint, error) {\n\tvar listenPort uint16',1)
    needle = '\t\t\tcase "PrivateKey":'
    assert needle in s
    s = s.replace(needle, '\t\t\tcase "ListenPort":\n\t\t\t\tv, err := strconv.ParseUint(val, 10, 16)\n\t\t\t\tif err != nil { return nil, errors.New("invalid ListenPort") }\n\t\t\t\tlistenPort = uint16(v)\n'+needle,1)
    pos = s.rfind('PrivateKey: privateKey,')
    assert pos >= 0
    s = s[:pos]+s[pos:].replace('PrivateKey: privateKey,', 'PrivateKey: privateKey,\n\t\t\tListenPort: listenPort,',1)
if 'var extended T.AwgOptions' not in s:
    s = s.replace('var listenPort uint16', 'var listenPort uint16\n\tvar extended T.AwgOptions',1)
    extra = ''.join(f'\t\t\tcase "{conf}":\n\t\t\t\textended.{f} = val\n' for f,_,conf in fields)
    extra += ''.join(f'''\t\t\tcase "{conf}":
                normalized := strings.ToLower(val)
                if normalized == "on" {{ normalized = "true" }}
                if normalized == "off" {{ normalized = "false" }}
                v, err := strconv.ParseBool(normalized)
                if err != nil {{ return nil, errors.New("invalid {conf}") }}
                extended.{f} = v
''' for f,_,conf in bools)
    s = s.replace('\t\t\tcase "PrivateKey":', extra+'\t\t\tcase "PrivateKey":',1)
    needle = '\t\tI5: i5,'
    assert needle in s
    s = s.replace(needle,needle+'\n'+''.join(f'\t\t{f}: extended.{f},\n' for f,_,_ in fields+bools),1)
    s = s.replace('case "PersistentKeepalive":', 'case "PersistentKeepalive":\n\t\t\t\tpeer.PersistentKeepalive = val',1)
    # Query links accept canonical .conf names and snake_case JSON names.
    needle = '\tif mtuStr, ok := u.Params["mtu"]; ok {'
    assert needle in s
    extra = '\topts.ListenPort = getUint16("listenport")\n'
    extra += '\topts.Peers[0].PersistentKeepalive = getOneOfN(u.Params, "", "persistentkeepalive", "keepalive")\n'
    extra += ''.join(f'\topts.Awg.{f} = getOneOfN(u.Params, "", "{conf.lower()}", "{key}")\n' for f,key,conf in fields)
    for f,key,conf in bools:
        extra += f'''\tif raw := getOneOfN(u.Params, "", "{conf.lower()}", "{key}"); raw != "" {{
            raw = strings.ToLower(raw)
            if raw == "on" {{ raw = "true" }}
            if raw == "off" {{ raw = "false" }}
            v, err := strconv.ParseBool(raw)
            if err != nil {{ return nil, errors.New("invalid {conf}") }}
            opts.Awg.{f} = v
        }}
'''
    s = s.replace(needle,extra+needle,1)
    p.write_text(s)
# Exercise real TCP and UDP through both generations, including 3.1 trailers,
# protected headers, content padding and ranged persistent keepalive.
p = box / 'transport/awg/h_device_test.go'
s = p.read_text()
if 'TestLinea_Awg31Loopback' not in s:
    s = s.replace('func TestH_DeviceLoopbackTunnel(t *testing.T) {', 'func TestH_DeviceLoopbackTunnel(t *testing.T) { hCheckLoopback(t, hObfuscation) }\n\nfunc TestLinea_Awg31Loopback(t *testing.T) {\n hCheckLoopback(t, hObfuscation + "\\ns3=20\\ns4=24\\nheader_protection_key=" + strings.Repeat("ab",32) + "\\nrandom_trailers=true\\ndisable_cookies=true\\ncontent_padding_addition=0-64\\nrekey_after_time=100-120\\nrekey_timeout=4-6\\nreject_after_time=170-190\\nkeepalive_timeout=8-12\\nmax_handshake_attempts=15-20")\n}\n\nfunc hCheckLoopback(t *testing.T, obfuscation string) {',1)
    # Only replace inside the helper, preserving the original AWG 2 test.
    pos = s.index('func hCheckLoopback')
    s = s[:pos] + s[pos:].replace('hStartTunnelPair(t, ctx, hObfuscation)', 'hStartTunnelPair(t, ctx, obfuscation)',1)
    s = s.replace('"strconv"', '"strconv"\n"strings"',1)
    p.write_text(s)

# Additional application-specific import regression lives with the patch source.
import shutil
shutil.copyfile(Path(__file__).with_name('awg31_import_test.go.txt'), root/'ray2sing/ray2sing/linea_awg31_test.go')
shutil.copyfile(Path(__file__).with_name('awg31_endpoint_test.go.txt'), box/'protocol/awg/linea_awg31_test.go')
