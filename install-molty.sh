#!/bin/bash
# ══════════════════════════════════════════════
#  🦞  OpenClaw Molty 桌面萌宠安装器  v2.1
#      原生 macOS App · 零依赖 · The Lobster Way
# ══════════════════════════════════════════════
set -e

REPO="shufanli/openclaw-pet"
PETS_DIR="$HOME/.openclaw/pets"
APP_DIR="$PETS_DIR/Molty.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
SWIFT_SRC="$PETS_DIR/molty.swift"
AGENT_PLIST="$HOME/Library/LaunchAgents/ai.openclaw.molty.plist"

RED='\033[0;31m'; GRN='\033[0;32m'; CYN='\033[0;36m'; YLW='\033[1;33m'; BLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${RED}  🦞  OpenClaw Molty 桌面萌宠${NC}"
echo -e "${CYN}      The Lobster Way · v2.1${NC}"
echo "  ─────────────────────────────────"
echo ""

# ── 1. 找 soul.md ─────────────────────────────
SOUL_FILE=""
for f in \
    "$HOME/.openclaw/workspace/soul.md" \
    "$HOME/.openclaw/soul.md" \
    "$HOME/.claude/SOUL.md" \
    "$HOME/.claude/soul.md" \
    "$HOME/soul.md"
do
    [ -f "$f" ] && SOUL_FILE="$f" && break
done

if [ -n "$SOUL_FILE" ]; then
    echo -e "  ${GRN}✓${NC} 找到 soul.md: $(echo "$SOUL_FILE" | sed "s|$HOME|~|g")"
    SOUL=$(cat "$SOUL_FILE" | tr '[:upper:]' '[:lower:]')
else
    echo -e "  ${YLW}⚠${NC} 未找到 soul.md，使用经典款（App 启动后仍会自动搜索）"
    SOUL=""
fi

# ── 2. 性格分析 ───────────────────────────────
c=0; cy=0; z=0
for w in social friend fun happy creative energetic art music humor laugh; do
    [[ "$SOUL" == *"$w"* ]] && ((c+=2)) || true
done
for w in code hack terminal engineer debug algorithm tech script api git data optimize; do
    [[ "$SOUL" == *"$w"* ]] && ((cy+=2)) || true
done
for w in calm peace balance mindful wisdom deep slow patient meditate philosophy reflect; do
    [[ "$SOUL" == *"$w"* ]] && ((z+=2)) || true
done
if   [ "$cy" -ge "$c" ] && [ "$cy" -ge "$z" ]; then PREVIEW="赛博 Molty ⚡"
elif [ "$z"  -ge "$c" ] && [ "$z"  -ge "$cy" ]; then PREVIEW="禅意 Molty ✦"
else PREVIEW="经典 Molty 🦞"; fi
echo -e "  ${GRN}✓${NC} 性格预测 → ${CYN}${BLD}${PREVIEW}${NC}"
echo ""

# ── 3. 创建目录 ───────────────────────────────
mkdir -p "$BIN_DIR"

# ── 4. 获取二进制（优先下载预编译，自动回退本地编译）─
get_binary() {
    local dest="$BIN_DIR/molty"

    # 尝试从 GitHub Releases 下载预编译版本
    echo -e "  ${CYN}⬇  下载预编译二进制...${NC}"
    local release_url
    release_url=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        2>/dev/null | grep '"browser_download_url"' | grep 'molty' | cut -d'"' -f4 | head -1)

    if [ -n "$release_url" ]; then
        if curl -fsSL "$release_url" -o "$dest" 2>/dev/null; then
            chmod +x "$dest"
            echo -e "  ${GRN}✓${NC} 下载成功（预编译 universal binary）"
            return 0
        fi
    fi

    echo -e "  ${YLW}⚠${NC} 下载失败，尝试本地编译..."

    # 回退：本地 swiftc 编译
    if ! command -v swiftc &>/dev/null; then
        echo -e "  ${RED}✗${NC} 未找到 swiftc，无法编译"
        echo ""
        echo "  请安装 Xcode Command Line Tools 后重试："
        echo "    xcode-select --install"
        exit 1
    fi

    write_swift_source "$SWIFT_SRC"

    echo -e "  ${CYN}⚙  本地编译中（首次约 15 秒）...${NC}"
    if swiftc -framework WebKit -O -o "$dest" "$SWIFT_SRC" 2>/tmp/molty_compile_err; then
        chmod +x "$dest"
        echo -e "  ${GRN}✓${NC} 本地编译成功"
        return 0
    else
        echo -e "  ${RED}✗${NC} 编译失败，错误信息："
        cat /tmp/molty_compile_err | head -5
        exit 1
    fi
}

write_swift_source() {
    local dest="$1"
    cat > "$dest" << 'SWIFT_EOF'
import AppKit
import WebKit

func analyzeSoul() -> String {
    let home = NSHomeDirectory()
    let paths = [
        home + "/.openclaw/workspace/soul.md",
        home + "/.openclaw/soul.md",
        home + "/.claude/SOUL.md",
        home + "/.claude/soul.md",
        home + "/soul.md"
    ]
    var soul = ""
    for p in paths {
        if let s = try? String(contentsOfFile: p, encoding: .utf8) { soul = s.lowercased(); break }
    }
    var c = 0, cy = 0, z = 0
    for w in ["social","friend","fun","happy","creative","energetic","art","music","humor","laugh","outgoing"] { if soul.contains(w) { c += 2 } }
    for w in ["code","hack","terminal","engineer","debug","algorithm","tech","script","api","git","data","optimize","coder"] { if soul.contains(w) { cy += 2 } }
    for w in ["calm","peace","balance","mindful","wisdom","deep","slow","patient","meditate","philosophy","reflect","quiet"] { if soul.contains(w) { z += 2 } }
    if cy >= c && cy >= z { return "cyber" }
    if z  >= c && z  >= cy { return "zen"   }
    return "classic"
}

let classicHTML = #"""
<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{background:transparent!important;width:200px;height:250px;overflow:hidden;-webkit-user-select:none}
@keyframes B{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
@keyframes WL{0%,100%{transform:rotate(0);transform-origin:80% 80%}40%{transform:rotate(-28deg);transform-origin:80% 80%}}
@keyframes WR{0%,100%{transform:rotate(0);transform-origin:20% 80%}40%{transform:rotate(28deg);transform-origin:20% 80%}}
@keyframes BL{0%,88%,100%{transform:scaleY(1)}93%{transform:scaleY(0.08)}}
@keyframes AL{0%,100%{transform:rotate(0);transform-origin:70% 100%}50%{transform:rotate(-8deg);transform-origin:70% 100%}}
@keyframes AR{0%,100%{transform:rotate(0);transform-origin:30% 100%}50%{transform:rotate(8deg);transform-origin:30% 100%}}
.b{animation:B 2s ease-in-out infinite}.cl{animation:WL 3s ease-in-out infinite .5s}
.cr{animation:WR 3s ease-in-out infinite}.ey{animation:BL 4s ease-in-out infinite}
.al{animation:AL 2.5s ease-in-out infinite}.ar{animation:AR 2.5s ease-in-out infinite .3s}
</style></head><body>
<svg viewBox="0 0 130 160" width="200" height="246" xmlns="http://www.w3.org/2000/svg">
<ellipse cx="65" cy="148" rx="30" ry="6" fill="#E8433A" opacity="0.12"/>
<g class="al"><path d="M 46 26 Q 28 12 18 2" stroke="#C0392B" stroke-width="2.5" fill="none" stroke-linecap="round"/><circle cx="18" cy="2" r="3" fill="#E8433A"/></g>
<g class="ar"><path d="M 84 26 Q 102 12 112 2" stroke="#C0392B" stroke-width="2.5" fill="none" stroke-linecap="round"/><circle cx="112" cy="2" r="3" fill="#E8433A"/></g>
<path d="M 50 30 Q 38 22 32 16" stroke="#C0392B" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.7"/>
<path d="M 80 30 Q 92 22 98 16" stroke="#C0392B" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.7"/>
<g class="b">
<ellipse cx="65" cy="44" rx="24" ry="20" fill="#E8433A"/><polygon points="65,18 59,30 71,30" fill="#C0392B"/>
<path d="M 42 46 Q 65 42 88 46" stroke="#C0392B" stroke-width="1.5" fill="none"/>
<rect x="46" y="32" width="7" height="11" rx="3.5" fill="#C0392B"/>
<rect x="77" y="32" width="7" height="11" rx="3.5" fill="#C0392B"/>
<g class="ey">
<circle cx="50" cy="31" r="10" fill="white"/><circle cx="80" cy="31" r="10" fill="white"/>
<circle cx="52" cy="32" r="6" fill="#1A0000"/><circle cx="82" cy="32" r="6" fill="#1A0000"/>
<circle cx="54" cy="29" r="2.5" fill="white"/><circle cx="84" cy="29" r="2.5" fill="white"/>
</g>
<path d="M 56 52 Q 65 58 74 52" stroke="#C0392B" stroke-width="2" fill="none" stroke-linecap="round"/>
<ellipse cx="65" cy="90" rx="20" ry="28" fill="#E8433A"/>
<path d="M 46 82 Q 65 78 84 82" stroke="#C0392B" stroke-width="1.5" fill="none"/>
<path d="M 46 92 Q 65 88 84 92" stroke="#C0392B" stroke-width="1.5" fill="none"/>
<path d="M 47 102 Q 65 98 83 102" stroke="#C0392B" stroke-width="1.5" fill="none"/>
<path d="M 48 80 Q 32 88 28 100" stroke="#C0392B" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="M 47 90 Q 30 100 27 112" stroke="#C0392B" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<path d="M 47 100 Q 32 110 30 122" stroke="#C0392B" stroke-width="2" fill="none" stroke-linecap="round"/>
<path d="M 82 80 Q 98 88 102 100" stroke="#C0392B" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="M 83 90 Q 100 100 103 112" stroke="#C0392B" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<path d="M 83 100 Q 98 110 100 122" stroke="#C0392B" stroke-width="2" fill="none" stroke-linecap="round"/>
<ellipse cx="65" cy="120" rx="15" ry="10" fill="#E8433A"/>
<ellipse cx="65" cy="130" rx="13" ry="9" fill="#D63B33"/>
<ellipse cx="42" cy="138" rx="13" ry="8" fill="#E8433A" transform="rotate(-30 42 138)"/>
<ellipse cx="65" cy="142" rx="12" ry="8" fill="#C0392B"/>
<ellipse cx="88" cy="138" rx="13" ry="8" fill="#E8433A" transform="rotate(30 88 138)"/>
</g>
<g class="cl">
<path d="M 46 68 Q 20 60 10 72 Q 4 82 12 90 Q 20 97 34 90 Q 42 86 46 78" fill="#E8433A" stroke="#C0392B" stroke-width="1"/>
<path d="M 10 72 Q 2 64 10 57 Q 18 50 24 60 Q 18 66 12 70" fill="#D63B33"/>
<path d="M 12 90 Q 4 96 10 103 Q 18 109 26 100 Q 20 95 14 91" fill="#D63B33"/>
<path d="M 14 72 L 22 82" stroke="#C0392B" stroke-width="1.5" stroke-linecap="round"/>
</g>
<g class="cr">
<path d="M 84 68 Q 110 60 120 72 Q 126 82 118 90 Q 110 97 96 90 Q 88 86 84 78" fill="#E8433A" stroke="#C0392B" stroke-width="1"/>
<path d="M 120 72 Q 128 64 120 57 Q 112 50 106 60 Q 112 66 118 70" fill="#D63B33"/>
<path d="M 118 90 Q 126 96 120 103 Q 112 109 104 100 Q 110 95 116 91" fill="#D63B33"/>
<path d="M 116 72 L 108 82" stroke="#C0392B" stroke-width="1.5" stroke-linecap="round"/>
</g>
</svg>
</body></html>
"""#

let cyberHTML = #"""
<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{background:transparent!important;width:200px;height:250px;overflow:hidden;-webkit-user-select:none}
@keyframes F{0%,100%{transform:translateY(0) rotate(0)}25%{transform:translateY(-6px) rotate(-1deg)}75%{transform:translateY(-4px) rotate(1deg)}}
@keyframes GW{0%,100%{filter:drop-shadow(0 0 8px #00FFCC) drop-shadow(0 0 20px rgba(0,255,204,.4))}50%{filter:drop-shadow(0 0 16px #00FFCC) drop-shadow(0 0 44px rgba(0,255,204,.7))}}
@keyframes ES{0%,100%{fill:#00FFCC}50%{fill:#FF2D78}}
@keyframes GL{0%,88%,100%{transform:translate(0)}91%{transform:translate(-2px,1px)}94%{transform:translate(2px,-1px)}}
@keyframes TY{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}
.b{animation:F 3s ease-in-out infinite,GL 8s ease-in-out infinite}.gw{animation:GW 2s ease-in-out infinite}
.ey{animation:ES 3s ease-in-out infinite}.cl{animation:TY 1.5s ease-in-out infinite}.cr{animation:TY 1.5s ease-in-out infinite .75s}
</style></head><body>
<svg viewBox="0 0 130 160" width="200" height="246" xmlns="http://www.w3.org/2000/svg">
<g opacity="0.12" font-family="monospace" font-size="8" fill="#00FFCC">
<text x="8" y="20">01</text><text x="8" y="32">10</text><text x="110" y="25">10</text><text x="110" y="37">01</text>
<text x="4" y="80">11</text><text x="115" y="75">00</text></g>
<g class="gw"><ellipse cx="65" cy="80" rx="45" ry="55" fill="none" stroke="#00FFCC" stroke-width="1" opacity="0.2"/></g>
<path d="M 46 26 Q 28 12 18 2" stroke="#00FFCC" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.8"/>
<circle cx="18" cy="2" r="3" fill="#00FFCC"/>
<path d="M 84 26 Q 102 12 112 2" stroke="#00FFCC" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.8"/>
<circle cx="112" cy="2" r="3" fill="#00FFCC"/>
<g class="b">
<ellipse cx="65" cy="44" rx="24" ry="20" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1.5" opacity="0.9"/>
<polygon points="65,18 59,30 71,30" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1"/>
<rect x="46" y="32" width="7" height="11" rx="3.5" fill="#0A0A14" stroke="#00FFCC" stroke-width="0.8"/>
<rect x="77" y="32" width="7" height="11" rx="3.5" fill="#0A0A14" stroke="#00FFCC" stroke-width="0.8"/>
<circle cx="50" cy="31" r="10" fill="#001A14" stroke="#00FFCC" stroke-width="1"/>
<circle cx="80" cy="31" r="10" fill="#001A14" stroke="#00FFCC" stroke-width="1"/>
<circle class="ey" cx="52" cy="32" r="6" fill="#00FFCC"/>
<circle class="ey" cx="82" cy="32" r="6" fill="#00FFCC" style="animation-delay:1.5s"/>
<line x1="42" y1="32" x2="58" y2="32" stroke="#fff" stroke-width="1.5" opacity="0.5"/>
<line x1="72" y1="32" x2="88" y2="32" stroke="#fff" stroke-width="1.5" opacity="0.5"/>
<path d="M 56 52 L 60 56 L 70 56 L 74 52 L 70 48 L 60 48 Z" fill="none" stroke="#00FFCC" stroke-width="1" opacity="0.7"/>
<text x="62" y="55" font-family="monospace" font-size="5" fill="#00FFCC">&gt;_</text>
<ellipse cx="65" cy="90" rx="20" ry="28" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1.2" opacity="0.8"/>
<path d="M 46 82 Q 65 78 84 82" stroke="#00FFCC" stroke-width="1" fill="none" opacity="0.5"/>
<path d="M 46 92 Q 65 88 84 92" stroke="#00FFCC" stroke-width="1" fill="none" opacity="0.5"/>
<path d="M 47 102 Q 65 98 83 102" stroke="#00FFCC" stroke-width="1" fill="none" opacity="0.5"/>
<circle cx="65" cy="82" r="2" fill="#00FFCC" opacity="0.6"/>
<circle cx="65" cy="92" r="2" fill="#FF2D78" opacity="0.6"/>
<path d="M 48 80 Q 32 88 28 100" stroke="#00FFCC" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.7"/>
<path d="M 47 90 Q 30 100 27 112" stroke="#00FFCC" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.6"/>
<path d="M 47 100 Q 32 110 30 122" stroke="#00FFCC" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.5"/>
<path d="M 82 80 Q 98 88 102 100" stroke="#00FFCC" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.7"/>
<path d="M 83 90 Q 100 100 103 112" stroke="#00FFCC" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.6"/>
<path d="M 83 100 Q 98 110 100 122" stroke="#00FFCC" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.5"/>
<ellipse cx="65" cy="120" rx="15" ry="10" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1" opacity="0.7"/>
<ellipse cx="65" cy="130" rx="13" ry="9" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1" opacity="0.6"/>
<ellipse cx="42" cy="138" rx="13" ry="8" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1" opacity="0.5" transform="rotate(-30 42 138)"/>
<ellipse cx="65" cy="142" rx="12" ry="8" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1" opacity="0.6"/>
<ellipse cx="88" cy="138" rx="13" ry="8" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1" opacity="0.5" transform="rotate(30 88 138)"/>
</g>
<g class="cl">
<path d="M 46 68 Q 20 60 10 72 Q 4 82 12 90 Q 20 97 34 90 Q 42 86 46 78" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1.5"/>
<path d="M 10 72 Q 2 64 10 57 Q 18 50 24 60 Q 18 66 12 70" fill="#001A14" stroke="#00FFCC" stroke-width="1"/>
<path d="M 12 90 Q 4 96 10 103 Q 18 109 26 100 Q 20 95 14 91" fill="#001A14" stroke="#00FFCC" stroke-width="1"/>
<path d="M 14 72 L 22 82" stroke="#FF2D78" stroke-width="1.5" stroke-linecap="round" opacity="0.8"/>
</g>
<g class="cr">
<path d="M 84 68 Q 110 60 120 72 Q 126 82 118 90 Q 110 97 96 90 Q 88 86 84 78" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1.5"/>
<path d="M 120 72 Q 128 64 120 57 Q 112 50 106 60 Q 112 66 118 70" fill="#001A14" stroke="#00FFCC" stroke-width="1"/>
<path d="M 118 90 Q 126 96 120 103 Q 112 109 104 100 Q 110 95 116 91" fill="#001A14" stroke="#00FFCC" stroke-width="1"/>
<path d="M 116 72 L 108 82" stroke="#FF2D78" stroke-width="1.5" stroke-linecap="round" opacity="0.8"/>
</g>
<text x="10" y="155" font-family="monospace" font-size="7" fill="#00FFCC" opacity="0.35">EXFOLIATE!</text>
</svg>
</body></html>
"""#

let zenHTML = #"""
<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{background:transparent!important;width:200px;height:262px;overflow:hidden;-webkit-user-select:none}
@keyframes ZF{0%,100%{transform:translateY(0) scale(1)}50%{transform:translateY(-14px) scale(1.02)}}
@keyframes AU{0%,100%{transform:scale(1);opacity:.3}50%{transform:scale(1.45);opacity:.08}}
@keyframes BR{0%,100%{transform:scale(1);opacity:.6}50%{transform:scale(1.15);opacity:1}}
@keyframes S1{0%{transform:translate(0,0) scale(1);opacity:.8}100%{transform:translate(-8px,-44px) scale(.2);opacity:0}}
@keyframes S2{0%{transform:translate(0,0) scale(1);opacity:.7}100%{transform:translate(10px,-40px) scale(.2);opacity:0}}
@keyframes S3{0%{transform:translate(0,0) scale(1);opacity:.6}100%{transform:translate(16px,-36px) scale(.2);opacity:0}}
.b{animation:ZF 4s ease-in-out infinite}.au{animation:AU 4s ease-in-out infinite}
.br{animation:BR 4s ease-in-out infinite}.s1{animation:S1 3s ease-out infinite}
.s2{animation:S2 3s ease-out infinite 1s}.s3{animation:S3 3s ease-out infinite 2s}
</style></head><body>
<svg viewBox="0 0 130 170" width="200" height="261" xmlns="http://www.w3.org/2000/svg">
<circle cx="15" cy="15" r="1" fill="#A78BFA" opacity="0.5"/>
<circle cx="115" cy="20" r="1.5" fill="#A78BFA" opacity="0.3"/>
<g class="s1"><text x="26" y="55" font-size="10" fill="#A78BFA">✦</text></g>
<g class="s2"><text x="96" y="65" font-size="8" fill="#C4B5FD">✧</text></g>
<g class="s3"><text x="46" y="45" font-size="7" fill="#A78BFA">·</text></g>
<g class="au"><circle cx="65" cy="85" r="52" fill="none" stroke="#A78BFA" stroke-width="1" opacity="0.15"/></g>
<g class="br"><circle cx="65" cy="85" r="38" fill="none" stroke="#C4B5FD" stroke-width="1.5" opacity="0.2"/></g>
<path d="M 46 26 Q 30 18 22 8" stroke="#7C3AED" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<circle cx="22" cy="8" r="3" fill="#A78BFA"/>
<path d="M 84 26 Q 100 18 108 8" stroke="#7C3AED" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<circle cx="108" cy="8" r="3" fill="#A78BFA"/>
<g class="b">
<ellipse cx="65" cy="44" rx="24" ry="20" fill="#EDE9FE" stroke="#A78BFA" stroke-width="1.5" opacity="0.8"/>
<polygon points="65,18 59,30 71,30" fill="#DDD6FE"/>
<rect x="46" y="32" width="7" height="11" rx="3.5" fill="#DDD6FE"/>
<rect x="77" y="32" width="7" height="11" rx="3.5" fill="#DDD6FE"/>
<circle cx="50" cy="31" r="10" fill="white"/><circle cx="80" cy="31" r="10" fill="white"/>
<path d="M 40 31 Q 50 22 60 31" fill="#EDE9FE"/>
<path d="M 70 31 Q 80 22 90 31" fill="#EDE9FE"/>
<circle cx="51" cy="33" r="5" fill="#5B21B6"/><circle cx="81" cy="33" r="5" fill="#5B21B6"/>
<circle cx="52" cy="31" r="2" fill="white" opacity="0.6"/><circle cx="82" cy="31" r="2" fill="white" opacity="0.6"/>
<path d="M 57 54 Q 65 60 73 54" stroke="#7C3AED" stroke-width="2" fill="none" stroke-linecap="round"/>
<ellipse cx="65" cy="90" rx="20" ry="28" fill="#EDE9FE" stroke="#A78BFA" stroke-width="1" opacity="0.6"/>
<circle cx="65" cy="90" r="8" fill="none" stroke="#A78BFA" stroke-width="1" opacity="0.4"/>
<circle cx="65" cy="90" r="4" fill="#C4B5FD" opacity="0.4"/>
<path d="M 48 80 Q 32 88 28 100" stroke="#A78BFA" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.6"/>
<path d="M 47 90 Q 30 100 27 112" stroke="#A78BFA" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.5"/>
<path d="M 47 100 Q 32 110 30 122" stroke="#A78BFA" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.4"/>
<path d="M 82 80 Q 98 88 102 100" stroke="#A78BFA" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.6"/>
<path d="M 83 90 Q 100 100 103 112" stroke="#A78BFA" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.5"/>
<path d="M 83 100 Q 98 110 100 122" stroke="#A78BFA" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.4"/>
<ellipse cx="65" cy="120" rx="15" ry="10" fill="#EDE9FE" stroke="#A78BFA" stroke-width="1" opacity="0.7"/>
<ellipse cx="65" cy="130" rx="13" ry="9" fill="#DDD6FE" stroke="#A78BFA" stroke-width="1" opacity="0.6"/>
<ellipse cx="42" cy="138" rx="13" ry="8" fill="#EDE9FE" stroke="#A78BFA" stroke-width="1" opacity="0.5" transform="rotate(-30 42 138)"/>
<ellipse cx="65" cy="142" rx="12" ry="8" fill="#C4B5FD" stroke="#A78BFA" stroke-width="1" opacity="0.5"/>
<ellipse cx="88" cy="138" rx="13" ry="8" fill="#EDE9FE" stroke="#A78BFA" stroke-width="1" opacity="0.5" transform="rotate(30 88 138)"/>
</g>
<path d="M 46 68 Q 20 60 10 72 Q 4 82 12 90 Q 20 97 34 90 Q 42 86 46 78" fill="#EDE9FE" stroke="#A78BFA" stroke-width="1.5"/>
<path d="M 10 72 Q 2 64 10 57 Q 18 50 24 60 Q 18 66 12 70" fill="#DDD6FE" stroke="#A78BFA" stroke-width="1"/>
<path d="M 12 90 Q 4 96 10 103 Q 18 109 26 100 Q 20 95 14 91" fill="#DDD6FE" stroke="#A78BFA" stroke-width="1"/>
<path d="M 84 68 Q 110 60 120 72 Q 126 82 118 90 Q 110 97 96 90 Q 88 86 84 78" fill="#EDE9FE" stroke="#A78BFA" stroke-width="1.5"/>
<path d="M 120 72 Q 128 64 120 57 Q 112 50 106 60 Q 112 66 118 70" fill="#DDD6FE" stroke="#A78BFA" stroke-width="1"/>
<path d="M 118 90 Q 126 96 120 103 Q 112 109 104 100 Q 110 95 116 91" fill="#DDD6FE" stroke="#A78BFA" stroke-width="1"/>
</svg>
</body></html>
"""#

class MoltyApp: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var refreshTimer: Timer?

    func petHTML(for style: String) -> String {
        switch style {
        case "cyber": return cyberHTML
        case "zen":   return zenHTML
        default:      return classicHTML
        }
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let style = analyzeSoul()
        let html  = petHTML(for: style)
        let screen = NSScreen.main!.visibleFrame
        let w: CGFloat = 200, h: CGFloat = 270
        let x = screen.maxX - w - 24
        let y = screen.minY + 24
        window = NSWindow(contentRect: NSRect(x: x, y: y, width: w, height: h),
                          styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        let cfg = WKWebViewConfiguration()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: w, height: h), configuration: cfg)
        webView.setValue(false, forKey: "drawsBackground")
        webView.loadHTMLString(html, baseURL: nil)
        window.contentView = webView
        window.orderFront(nil)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let newHTML = self.petHTML(for: analyzeSoul())
            DispatchQueue.main.async { self.webView.loadHTMLString(newHTML, baseURL: nil) }
        }
    }
    func applicationWillTerminate(_ n: Notification) { refreshTimer?.invalidate() }
}

let app = NSApplication.shared
let delegate = MoltyApp()
app.delegate = delegate
app.run()
SWIFT_EOF
}

get_binary

# ── 5. Info.plist ──────────────────────────────
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>   <string>molty</string>
    <key>CFBundleIdentifier</key>   <string>ai.openclaw.molty</string>
    <key>CFBundleName</key>         <string>Molty</string>
    <key>CFBundlePackageType</key>  <string>APPL</string>
    <key>CFBundleVersion</key>      <string>2.1</string>
    <key>LSUIElement</key>          <true/>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST_EOF

xattr -dr com.apple.quarantine "$APP_DIR" 2>/dev/null || true

# ── 6. LaunchAgent ────────────────────────────
cat > "$AGENT_PLIST" << AGENT_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>             <string>ai.openclaw.molty</string>
    <key>ProgramArguments</key>
    <array><string>$BIN_DIR/molty</string></array>
    <key>RunAtLoad</key>         <true/>
    <key>KeepAlive</key>         <true/>
    <key>StandardErrorPath</key> <string>$PETS_DIR/molty.log</string>
</dict>
</plist>
AGENT_EOF

launchctl unload "$AGENT_PLIST" 2>/dev/null || true
pkill -f "Molty.app" 2>/dev/null || true
launchctl load "$AGENT_PLIST"
echo -e "  ${GRN}✓${NC} LaunchAgent 已注册（开机自动启动）"

sleep 0.5
open "$APP_DIR"

echo ""
echo "  ─────────────────────────────────"
echo -e "  ${CYN}${BLD}🦞  ${PREVIEW} 已出现在桌面右下角！${NC}"
echo ""
echo "  · 透明背景，点击穿透，常驻所有桌面"
echo "  · soul.md 更新后 10 分钟内自动切换风格"
echo "  · 卸载：launchctl unload $AGENT_PLIST"
echo ""
