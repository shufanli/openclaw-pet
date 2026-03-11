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
for w in social friend fun happy creative energetic art music humor laugh 社交 朋友 快乐 开心 创意 活力 艺术 音乐 幽默 搞笑 欢乐 热情; do
    [[ "$SOUL" == *"$w"* ]] && ((c+=2)) || true
done
for w in code hack terminal engineer debug algorithm tech script api git data optimize 代码 技术 工程师 调试 算法 编程 脚本 数据 优化 极客 开发 程序; do
    [[ "$SOUL" == *"$w"* ]] && ((cy+=2)) || true
done
for w in calm peace balance mindful wisdom deep slow patient meditate philosophy reflect 平静 平和 平衡 正念 智慧 深度 耐心 冥想 哲学 反思 禅 宁静; do
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

// ── Soul 分析 ─────────────────────────────────────────────────────────────────
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
    for w in ["social","friend","fun","happy","creative","energetic","art","music","humor","laugh","outgoing","社交","朋友","快乐","开心","创意","活力","艺术","音乐","幽默","搞笑","欢乐","热情"] { if soul.contains(w) { c += 2 } }
    for w in ["code","hack","terminal","engineer","debug","algorithm","tech","script","api","git","data","optimize","coder","代码","技术","工程师","调试","算法","编程","脚本","数据","优化","极客","开发","程序"] { if soul.contains(w) { cy += 2 } }
    for w in ["calm","peace","balance","mindful","wisdom","deep","slow","patient","meditate","philosophy","reflect","quiet","平静","平和","平衡","正念","智慧","深度","耐心","冥想","哲学","反思","禅","宁静"] { if soul.contains(w) { z += 2 } }
    if cy >= c && cy >= z { return "cyber" }
    if z  >= c && z  >= cy { return "zen"   }
    return "classic"
}

// ── Classic 🦞 ────────────────────────────────────────────────────────────────
let classicHTML = #"""
<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
*{margin:0;padding:0;box-sizing:border-box}
html{background:transparent!important;width:100px;height:145px;overflow:hidden}body{background:transparent!important;width:200px;height:290px;overflow:hidden;-webkit-user-select:none;font-family:-apple-system,sans-serif;transform:scale(.5);transform-origin:top left}
@keyframes B{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
@keyframes WL{0%,100%{transform:rotate(0);transform-origin:80% 80%}40%{transform:rotate(-28deg);transform-origin:80% 80%}}
@keyframes WR{0%,100%{transform:rotate(0);transform-origin:20% 80%}40%{transform:rotate(28deg);transform-origin:20% 80%}}
@keyframes BLK{0%,88%,100%{transform:scaleY(1)}93%{transform:scaleY(0.08)}}
@keyframes AL{0%,100%{transform:rotate(0);transform-origin:70% 100%}50%{transform:rotate(-8deg);transform-origin:70% 100%}}
@keyframes AR{0%,100%{transform:rotate(0);transform-origin:30% 100%}50%{transform:rotate(8deg);transform-origin:30% 100%}}
@keyframes JMP{0%{transform:translateY(0) scale(1)}20%{transform:translateY(-30px) scale(1.08) rotate(-6deg)}60%{transform:translateY(-18px) scale(0.95) rotate(4deg)}85%{transform:translateY(-3px) rotate(-1deg)}100%{transform:translateY(0) scale(1) rotate(0)}}
@keyframes SHK{0%,100%{transform:translateX(0) rotate(0)}15%{transform:translateX(-9px) rotate(-6deg)}35%{transform:translateX(9px) rotate(6deg)}55%{transform:translateX(-6px) rotate(-4deg)}75%{transform:translateX(6px) rotate(4deg)}}
@keyframes DRG{0%,100%{transform:rotate(-4deg) scale(1.05)}50%{transform:rotate(4deg) scale(1.05)}}
@keyframes SPIN{0%{transform:scale(1) rotate(0)}40%{transform:scale(1.2) rotate(200deg) translateY(-20px)}100%{transform:scale(1) rotate(360deg)}}
.b{animation:B 2s ease-in-out infinite;cursor:grab}
.cl{animation:WL 3s ease-in-out infinite .5s}.cr{animation:WR 3s ease-in-out infinite}
.ey{animation:BLK 4s ease-in-out infinite}.al{animation:AL 2.5s ease-in-out infinite}.ar{animation:AR 2.5s ease-in-out infinite .3s}
.b:hover{filter:brightness(1.15) drop-shadow(0 0 10px rgba(232,67,58,0.5))}
.b.jmp{animation:B 2s ease-in-out infinite,JMP 0.6s ease-out!important}
.b.shk{animation:SHK 0.55s ease-in-out!important}
.b.drg{animation:DRG 0.35s ease-in-out infinite!important;cursor:grabbing}
.b.spin{animation:SPIN 0.65s cubic-bezier(.36,.07,.19,.97) forwards!important;cursor:wait}
.bubble{position:absolute;top:3px;left:50%;transform:translateX(-50%) scale(0.8) translateY(5px);background:#fff;border:2.5px solid #E8433A;border-radius:16px;padding:5px 14px;font-size:12px;font-weight:700;color:#C0392B;white-space:nowrap;opacity:0;transition:all 0.22s cubic-bezier(.34,1.56,.64,1);pointer-events:none;z-index:10;box-shadow:0 4px 16px rgba(232,67,58,0.18)}
.bubble.show{opacity:1;transform:translateX(-50%) scale(1) translateY(0)}
.bubble::after{content:'';position:absolute;bottom:-7px;left:50%;transform:translateX(-50%);border:4px solid transparent;border-top-color:#E8433A}
</style></head><body>
<div class="bubble" id="bubble"></div>
<svg viewBox="0 0 130 160" width="196" height="241" xmlns="http://www.w3.org/2000/svg" style="margin:26px auto 0;display:block">
<ellipse cx="65" cy="148" rx="30" ry="6" fill="#E8433A" opacity="0.12"/>
<g class="al"><path d="M 46 26 Q 28 12 18 2" stroke="#C0392B" stroke-width="2.5" fill="none" stroke-linecap="round"/><circle cx="18" cy="2" r="3" fill="#E8433A"/></g>
<g class="ar"><path d="M 84 26 Q 102 12 112 2" stroke="#C0392B" stroke-width="2.5" fill="none" stroke-linecap="round"/><circle cx="112" cy="2" r="3" fill="#E8433A"/></g>
<path d="M 50 30 Q 38 22 32 16" stroke="#C0392B" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.7"/>
<path d="M 80 30 Q 92 22 98 16" stroke="#C0392B" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.7"/>
<g class="b" id="body">
<ellipse cx="65" cy="44" rx="24" ry="20" fill="#E8433A"/>
<polygon points="65,18 59,30 71,30" fill="#C0392B"/>
<path d="M 42 46 Q 65 42 88 46" stroke="#C0392B" stroke-width="1.5" fill="none"/>
<rect x="46" y="32" width="7" height="11" rx="3.5" fill="#C0392B"/>
<rect x="77" y="32" width="7" height="11" rx="3.5" fill="#C0392B"/>
<g class="ey">
<circle cx="50" cy="31" r="10" fill="white"/><circle cx="80" cy="31" r="10" fill="white"/>
<circle id="plL" cx="52" cy="32" r="6" fill="#1A0000"/>
<circle id="plR" cx="82" cy="32" r="6" fill="#1A0000"/>
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
<script>
const MSGS=["今天也要努力！","龙虾永不摆烂！","蜕壳中...","摸鱼一下？","别戳我！","好饿啊...","✨加油✨","嗷嗷嗷！","哼哼哼","大虾驾到～"];
const IDLE=["...","👀","嗯~","哈欠～🥱","困了zZ","嘿！在吗？","（若有所思）","嘿嘿","小摸一下鱼","想什么呢"];
let mi=0,ii=0,bt,cc=0,ct;
const bub=document.getElementById('bubble');
const body=document.getElementById('body');
const plL=document.getElementById('plL');
const plR=document.getElementById('plR');
function showBubble(t,d){clearTimeout(bt);bub.textContent=t;bub.classList.add('show');bt=setTimeout(()=>bub.classList.remove('show'),d||2400);}
function onPetClick(){
  cc++;clearTimeout(ct);ct=setTimeout(()=>cc=0,700);
  if(cc>=5){cc=0;body.classList.remove('shk');void body.offsetWidth;body.classList.add('shk');setTimeout(()=>body.classList.remove('shk'),600);showBubble('😵 停！别戳了！',2000);return;}
  body.classList.remove('jmp');void body.offsetWidth;body.classList.add('jmp');
  showBubble(MSGS[mi++%MSGS.length]);setTimeout(()=>body.classList.remove('jmp'),650);
}
function onDragStart(){body.classList.remove('jmp');body.classList.add('drg');showBubble('woah～🌀',1200);}
function onDragEnd(){body.classList.remove('drg');}
function onSkinSwitch(next){body.classList.remove('jmp','shk','drg');void body.offsetWidth;body.classList.add('spin');showBubble('✨ '+next,900);}
function movePupil(el,bx,by,tx,ty){const dx=tx-bx,dy=ty-by,d=Math.sqrt(dx*dx+dy*dy),R=4,s=d>R?R/d:1;el.setAttribute('cx',bx+dx*s);el.setAttribute('cy',by+dy*s);}
document.addEventListener('mousemove',function(e){
  const r=document.querySelector('svg').getBoundingClientRect();
  const sx=(e.clientX-r.left)/r.width*130,sy=(e.clientY-r.top)/r.height*160;
  movePupil(plL,50,31,sx,sy);movePupil(plR,80,31,sx,sy);
});
(function idle(){setTimeout(function(){showBubble(IDLE[ii++%IDLE.length],2200);idle();},14000+Math.random()*16000);})();
</script></body></html>
"""#

// ── Cyber ⚡ ───────────────────────────────────────────────────────────────────
let cyberHTML = #"""
<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
*{margin:0;padding:0;box-sizing:border-box}
html{background:transparent!important;width:100px;height:145px;overflow:hidden}body{background:transparent!important;width:200px;height:290px;overflow:hidden;-webkit-user-select:none;font-family:monospace;transform:scale(.5);transform-origin:top left}
@keyframes F{0%,100%{transform:translateY(0) rotate(0)}25%{transform:translateY(-6px) rotate(-1deg)}75%{transform:translateY(-4px) rotate(1deg)}}
@keyframes GW{0%,100%{filter:drop-shadow(0 0 8px #00FFCC) drop-shadow(0 0 20px rgba(0,255,204,.4))}50%{filter:drop-shadow(0 0 16px #00FFCC) drop-shadow(0 0 44px rgba(0,255,204,.7))}}
@keyframes ES{0%,100%{fill:#00FFCC}50%{fill:#FF2D78}}
@keyframes GL{0%,88%,100%{transform:translate(0)}91%{transform:translate(-2px,1px)}94%{transform:translate(2px,-1px)}}
@keyframes TY{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}
@keyframes JMP{0%{transform:translateY(0) scale(1)}20%{transform:translateY(-28px) scale(1.06) rotate(-4deg)}60%{transform:translateY(-16px) scale(0.96) rotate(3deg)}85%{transform:translateY(-2px)}100%{transform:translateY(0) scale(1) rotate(0)}}
@keyframes SHK{0%,100%{transform:translateX(0)}15%{transform:translateX(-8px)}35%{transform:translateX(8px)}55%{transform:translateX(-5px)}75%{transform:translateX(5px)}}
@keyframes DRG{0%,100%{transform:rotate(-3deg) scale(1.04)}50%{transform:rotate(3deg) scale(1.06)}}
@keyframes SPIN{0%{transform:scale(1) rotate(0)}40%{transform:scale(1.2) rotate(200deg) translateY(-20px)}100%{transform:scale(1) rotate(360deg)}}
@keyframes SCAN{0%{transform:translateY(-100%)}100%{transform:translateY(400%)}}
.b{animation:F 3s ease-in-out infinite,GL 8s ease-in-out infinite;cursor:grab}
.gw{animation:GW 2s ease-in-out infinite}.ey{animation:ES 3s ease-in-out infinite}
.cl{animation:TY 1.5s ease-in-out infinite}.cr{animation:TY 1.5s ease-in-out infinite .75s}
.b:hover{filter:drop-shadow(0 0 20px #00FFCC) drop-shadow(0 0 40px rgba(0,255,204,0.6))!important}
.b.jmp{animation:F 3s ease-in-out infinite,JMP 0.55s ease-out!important}
.b.shk{animation:SHK 0.5s ease-in-out!important}
.b.drg{animation:DRG 0.3s ease-in-out infinite!important;cursor:grabbing}
.b.spin{animation:SPIN 0.65s cubic-bezier(.36,.07,.19,.97) forwards!important;cursor:wait}
.bubble{position:absolute;top:3px;left:50%;transform:translateX(-50%) scale(0.85) translateY(4px);background:#0D1A14;border:1px solid #00FFCC;border-radius:4px;padding:5px 14px;font-size:11px;color:#00FFCC;white-space:nowrap;opacity:0;transition:all 0.15s ease;pointer-events:none;z-index:10;box-shadow:0 0 14px rgba(0,255,204,0.35);text-shadow:0 0 8px #00FFCC;letter-spacing:0.05em}
.bubble::before{content:'> ';opacity:0.6}
.bubble.show{opacity:1;transform:translateX(-50%) scale(1) translateY(0)}
.bubble::after{content:'';position:absolute;bottom:-6px;left:50%;transform:translateX(-50%);border:4px solid transparent;border-top-color:#00FFCC}
.scanline{position:absolute;top:0;left:0;width:100%;height:3px;background:linear-gradient(transparent,rgba(0,255,204,0.08),transparent);animation:SCAN 4s linear infinite;pointer-events:none;z-index:5}
</style></head><body>
<div class="bubble" id="bubble"></div>
<div class="scanline"></div>
<svg viewBox="0 0 130 160" width="196" height="241" xmlns="http://www.w3.org/2000/svg" style="margin:26px auto 0;display:block">
<g opacity="0.12" font-family="monospace" font-size="8" fill="#00FFCC">
<text x="8" y="20">01</text><text x="8" y="32">10</text><text x="110" y="25">10</text><text x="110" y="37">01</text>
<text x="4" y="80">11</text><text x="115" y="75">00</text></g>
<g class="gw"><ellipse cx="65" cy="80" rx="45" ry="55" fill="none" stroke="#00FFCC" stroke-width="1" opacity="0.2"/></g>
<path d="M 46 26 Q 28 12 18 2" stroke="#00FFCC" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.8"/>
<circle cx="18" cy="2" r="3" fill="#00FFCC"/>
<path d="M 84 26 Q 102 12 112 2" stroke="#00FFCC" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.8"/>
<circle cx="112" cy="2" r="3" fill="#00FFCC"/>
<g class="b" id="body">
<ellipse cx="65" cy="44" rx="24" ry="20" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1.5" opacity="0.9"/>
<polygon points="65,18 59,30 71,30" fill="#0D0D1A" stroke="#00FFCC" stroke-width="1"/>
<rect x="46" y="32" width="7" height="11" rx="3.5" fill="#0A0A14" stroke="#00FFCC" stroke-width="0.8"/>
<rect x="77" y="32" width="7" height="11" rx="3.5" fill="#0A0A14" stroke="#00FFCC" stroke-width="0.8"/>
<circle cx="50" cy="31" r="10" fill="#001A14" stroke="#00FFCC" stroke-width="1"/>
<circle cx="80" cy="31" r="10" fill="#001A14" stroke="#00FFCC" stroke-width="1"/>
<circle class="ey" id="plL" cx="52" cy="32" r="6" fill="#00FFCC"/>
<circle class="ey" id="plR" cx="82" cy="32" r="6" fill="#00FFCC" style="animation-delay:1.5s"/>
<line x1="42" y1="32" x2="58" y2="32" stroke="#fff" stroke-width="1.5" opacity="0.4"/>
<line x1="72" y1="32" x2="88" y2="32" stroke="#fff" stroke-width="1.5" opacity="0.4"/>
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
<script>
const MSGS=["EXFOLIATE!","git push --force","sudo make me","while(true){hustle()}","segfault in soul.md","// TODO: sleep","rm -rf 拖延症","hello, world!","404: 摸鱼未找到","npm install life"];
const IDLE=["pinging...","null","> _","loading...","404:motivation","[object Object]","undefined","NaN","..."];
let mi=0,ii=0,bt,cc=0,ct;
const bub=document.getElementById('bubble');
const body=document.getElementById('body');
const plL=document.getElementById('plL');
const plR=document.getElementById('plR');
function showBubble(t,d){clearTimeout(bt);bub.textContent=t;bub.classList.add('show');bt=setTimeout(()=>bub.classList.remove('show'),d||2400);}
function onPetClick(){
  cc++;clearTimeout(ct);ct=setTimeout(()=>cc=0,700);
  if(cc>=5){cc=0;body.classList.remove('shk');void body.offsetWidth;body.classList.add('shk');setTimeout(()=>body.classList.remove('shk'),600);showBubble('ERROR: too many requests',2200);return;}
  body.classList.remove('jmp');void body.offsetWidth;body.classList.add('jmp');
  showBubble(MSGS[mi++%MSGS.length]);setTimeout(()=>body.classList.remove('jmp'),650);
}
function onDragStart(){body.classList.remove('jmp');body.classList.add('drg');showBubble('DRAG EVENT FIRED',1000);}
function onDragEnd(){body.classList.remove('drg');}
function onSkinSwitch(next){body.classList.remove('jmp','shk','drg');void body.offsetWidth;body.classList.add('spin');showBubble('> '+next,900);}
function movePupil(el,bx,by,tx,ty){const dx=tx-bx,dy=ty-by,d=Math.sqrt(dx*dx+dy*dy),R=4,s=d>R?R/d:1;el.setAttribute('cx',bx+dx*s);el.setAttribute('cy',by+dy*s);}
document.addEventListener('mousemove',function(e){
  const r=document.querySelector('svg').getBoundingClientRect();
  const sx=(e.clientX-r.left)/r.width*130,sy=(e.clientY-r.top)/r.height*160;
  movePupil(plL,50,31,sx,sy);movePupil(plR,80,31,sx,sy);
});
(function idle(){setTimeout(function(){showBubble(IDLE[ii++%IDLE.length],2200);idle();},14000+Math.random()*16000);})();
</script></body></html>
"""#

// ── Zen ✦ ─────────────────────────────────────────────────────────────────────
let zenHTML = #"""
<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
*{margin:0;padding:0;box-sizing:border-box}
html{background:transparent!important;width:100px;height:145px;overflow:hidden}body{background:transparent!important;width:200px;height:290px;overflow:hidden;-webkit-user-select:none;font-family:-apple-system,sans-serif;transform:scale(.5);transform-origin:top left}
@keyframes ZF{0%,100%{transform:translateY(0) scale(1)}50%{transform:translateY(-14px) scale(1.02)}}
@keyframes AU{0%,100%{transform:scale(1);opacity:.3}50%{transform:scale(1.45);opacity:.08}}
@keyframes BR{0%,100%{transform:scale(1);opacity:.6}50%{transform:scale(1.15);opacity:1}}
@keyframes S1{0%{transform:translate(0,0) scale(1);opacity:.8}100%{transform:translate(-8px,-44px) scale(.2);opacity:0}}
@keyframes S2{0%{transform:translate(0,0) scale(1);opacity:.7}100%{transform:translate(10px,-40px) scale(.2);opacity:0}}
@keyframes S3{0%{transform:translate(0,0) scale(1);opacity:.6}100%{transform:translate(16px,-36px) scale(.2);opacity:0}}
@keyframes JMP{0%{transform:translateY(0) scale(1)}25%{transform:translateY(-20px) scale(1.05)}60%{transform:translateY(-12px) scale(0.97)}85%{transform:translateY(-2px)}100%{transform:translateY(0) scale(1)}}
@keyframes SHK{0%,100%{transform:rotate(0)}20%{transform:rotate(-5deg)}40%{transform:rotate(5deg)}60%{transform:rotate(-3deg)}80%{transform:rotate(3deg)}}
@keyframes DRG{0%,100%{transform:rotate(-2deg) scale(1.03)}50%{transform:rotate(2deg) scale(1.03)}}
@keyframes SPIN{0%{transform:scale(1) rotate(0)}40%{transform:scale(1.15) rotate(200deg) translateY(-16px)}100%{transform:scale(1) rotate(360deg)}}
.b{animation:ZF 4s ease-in-out infinite;cursor:grab}
.au{animation:AU 4s ease-in-out infinite}.br{animation:BR 4s ease-in-out infinite}
.s1{animation:S1 3s ease-out infinite}.s2{animation:S2 3s ease-out infinite 1s}.s3{animation:S3 3s ease-out infinite 2s}
.b:hover{filter:drop-shadow(0 0 16px rgba(167,139,250,0.6)) brightness(1.08)}
.b.jmp{animation:ZF 4s ease-in-out infinite,JMP 0.7s ease-out!important}
.b.shk{animation:SHK 0.6s ease-in-out!important}
.b.drg{animation:DRG 0.45s ease-in-out infinite!important;cursor:grabbing}
.b.spin{animation:SPIN 0.65s cubic-bezier(.36,.07,.19,.97) forwards!important;cursor:wait}
.bubble{position:absolute;top:3px;left:50%;transform:translateX(-50%) scale(0.85) translateY(5px);background:rgba(237,233,254,0.94);border:1.5px solid #A78BFA;border-radius:20px;padding:6px 16px;font-size:12px;color:#5B21B6;white-space:nowrap;opacity:0;transition:all 0.35s cubic-bezier(.34,1.56,.64,1);pointer-events:none;z-index:10;backdrop-filter:blur(8px);box-shadow:0 4px 20px rgba(167,139,250,0.2)}
.bubble.show{opacity:1;transform:translateX(-50%) scale(1) translateY(0)}
.bubble::after{content:'';position:absolute;bottom:-6px;left:50%;transform:translateX(-50%);border:4px solid transparent;border-top-color:#A78BFA}
</style></head><body>
<div class="bubble" id="bubble"></div>
<svg viewBox="0 0 130 170" width="192" height="251" xmlns="http://www.w3.org/2000/svg" style="margin:26px auto 0;display:block">
<circle cx="15" cy="15" r="1" fill="#A78BFA" opacity="0.5"/>
<circle cx="115" cy="20" r="1.5" fill="#A78BFA" opacity="0.3"/>
<g class="s1"><text x="26" y="55" font-size="10" fill="#A78BFA">✦</text></g>
<g class="s2"><text x="96" y="65" font-size="8" fill="#C4B5FD">✧</text></g>
<g class="s3"><text x="46" y="45" font-size="7" fill="#A78BFA">·</text></g>
<g class="au"><circle cx="65" cy="90" r="52" fill="none" stroke="#A78BFA" stroke-width="1" opacity="0.15"/></g>
<g class="br"><circle cx="65" cy="90" r="38" fill="none" stroke="#C4B5FD" stroke-width="1.5" opacity="0.2"/></g>
<path d="M 46 26 Q 30 18 22 8" stroke="#7C3AED" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<circle cx="22" cy="8" r="3" fill="#A78BFA"/>
<path d="M 84 26 Q 100 18 108 8" stroke="#7C3AED" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<circle cx="108" cy="8" r="3" fill="#A78BFA"/>
<g class="b" id="body">
<ellipse cx="65" cy="44" rx="24" ry="20" fill="#EDE9FE" stroke="#A78BFA" stroke-width="1.5" opacity="0.8"/>
<polygon points="65,18 59,30 71,30" fill="#DDD6FE"/>
<rect x="46" y="32" width="7" height="11" rx="3.5" fill="#DDD6FE"/>
<rect x="77" y="32" width="7" height="11" rx="3.5" fill="#DDD6FE"/>
<circle cx="50" cy="31" r="10" fill="white"/><circle cx="80" cy="31" r="10" fill="white"/>
<path d="M 40 31 Q 50 22 60 31" fill="#EDE9FE"/>
<path d="M 70 31 Q 80 22 90 31" fill="#EDE9FE"/>
<circle id="plL" cx="51" cy="33" r="5" fill="#5B21B6"/>
<circle id="plR" cx="81" cy="33" r="5" fill="#5B21B6"/>
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
<script>
const MSGS=["呼...","🌸","此刻即永恒","随遇而安","无为而无不为","🍃","深呼吸~","...","万物静观皆自得","心如止水"];
const IDLE=["🌙","静","...","🍃","在","无","🌸","呼～","虚空",""];
let mi=0,ii=0,bt,cc=0,ct;
const bub=document.getElementById('bubble');
const body=document.getElementById('body');
const plL=document.getElementById('plL');
const plR=document.getElementById('plR');
function showBubble(t,d){clearTimeout(bt);bub.textContent=t;bub.classList.add('show');bt=setTimeout(()=>bub.classList.remove('show'),d||2800);}
function onPetClick(){
  cc++;clearTimeout(ct);ct=setTimeout(()=>cc=0,800);
  if(cc>=5){cc=0;body.classList.remove('shk');void body.offsetWidth;body.classList.add('shk');setTimeout(()=>body.classList.remove('shk'),650);showBubble('🌀 心乱了...',2400);return;}
  body.classList.remove('jmp');void body.offsetWidth;body.classList.add('jmp');
  showBubble(MSGS[mi++%MSGS.length]);setTimeout(()=>body.classList.remove('jmp'),750);
}
function onDragStart(){body.classList.remove('jmp');body.classList.add('drg');showBubble('随风而动～',1400);}
function onDragEnd(){body.classList.remove('drg');}
function onSkinSwitch(next){body.classList.remove('jmp','shk','drg');void body.offsetWidth;body.classList.add('spin');showBubble('🌸 '+next,900);}
function movePupil(el,bx,by,tx,ty){const dx=tx-bx,dy=ty-by,d=Math.sqrt(dx*dx+dy*dy),R=3,s=d>R?R/d:1;el.setAttribute('cx',bx+dx*s);el.setAttribute('cy',by+dy*s);}
document.addEventListener('mousemove',function(e){
  const r=document.querySelector('svg').getBoundingClientRect();
  const sx=(e.clientX-r.left)/r.width*130,sy=(e.clientY-r.top)/r.height*170;
  movePupil(plL,51,33,sx,sy);movePupil(plR,81,33,sx,sy);
});
(function idle(){setTimeout(function(){const t=IDLE[ii++%IDLE.length];if(t)showBubble(t,2600);idle();},16000+Math.random()*18000);})();
</script></body></html>
"""#

// ── App ───────────────────────────────────────────────────────────────────────
class MoltyApp: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var refreshTimer: Timer?
    var localMonitors: [Any] = []
    let skinOrder = ["classic", "cyber", "zen"]
    let skinNames  = ["classic": "⚡ 赛博 Molty", "cyber": "✦ 禅意 Molty", "zen": "🦞 经典 Molty"]
    var currentSkin = "classic"

    func petHTML(for style: String) -> String {
        switch style {
        case "cyber": return cyberHTML
        case "zen":   return zenHTML
        default:      return classicHTML
        }
    }

    func nextSkin() -> String {
        let idx = (skinOrder.firstIndex(of: currentSkin) ?? 0) + 1
        return skinOrder[idx % skinOrder.count]
    }

    func js(_ code: String) {
        webView.evaluateJavaScript(code, completionHandler: nil)
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        currentSkin = analyzeSoul()
        let screen = NSScreen.main!.visibleFrame
        let w: CGFloat = 100, h: CGFloat = 145
        let x = screen.maxX - w - 24
        let y = screen.minY + 24

        window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: w, height: h),
            styleMask: .borderless, backing: .buffered, defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = false   // always interactive (100×145 is small)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        let cfg = WKWebViewConfiguration()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: w, height: h), configuration: cfg)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = self
        webView.loadHTMLString(petHTML(for: currentSkin), baseURL: nil)
        window.contentView = webView
        window.orderFront(nil)

        // Intercept left-click before WKWebView — use trackEvents for reliable drag/up even outside window
        if let m = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown, handler: { [weak self] event in
            guard let self = self else { return event }
            self.startDragTracking(event)
            return nil   // consume: WKWebView never sees mouseDown
        }) { localMonitors.append(m) }

        // Consume right-click before WKWebView (prevents "Reload Page" context menu)
        if let m = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown, handler: { [weak self] event in
            guard let self = self else { return event }
            self.handleRightClick()
            return nil
        }) { localMonitors.append(m) }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentSkin = analyzeSoul()
            self.webView.loadHTMLString(self.petHTML(for: self.currentSkin), baseURL: nil)
        }
    }

    // Synchronous drag loop — trackEvents tracks mouse even outside the window
    func startDragTracking(_ downEvent: NSEvent) {
        let startScreen = window.convertPoint(toScreen: downEvent.locationInWindow)
        let startOrigin = window.frame.origin
        var dragging = false

        window.trackEvents(
            matching: [.leftMouseDragged, .leftMouseUp],
            timeout: NSEvent.foreverDuration,
            mode: .eventTracking
        ) { [weak self] event, stop in
            guard let self = self, let event = event else { stop.pointee = true; return }
            switch event.type {
            case .leftMouseDragged:
                let cur = self.window.convertPoint(toScreen: event.locationInWindow)
                let dx = cur.x - startScreen.x
                let dy = cur.y - startScreen.y
                if abs(dx) > 3 || abs(dy) > 3 {
                    if !dragging {
                        dragging = true
                        self.js("typeof onDragStart==='function'&&onDragStart()")
                    }
                    self.window.setFrameOrigin(NSPoint(x: startOrigin.x + dx, y: startOrigin.y + dy))
                }
            case .leftMouseUp:
                if dragging {
                    self.js("typeof onDragEnd==='function'&&onDragEnd()")
                } else {
                    self.js("typeof onPetClick==='function'&&onPetClick()")
                    NSWorkspace.shared.open(URL(string: "http://127.0.0.1:18789/")!)
                }
                stop.pointee = true
            default: break
            }
        }
    }

    func handleRightClick() {
        let next = nextSkin()
        let displayName = skinNames[next] ?? next
        js("typeof onSkinSwitch==='function'&&onSkinSwitch('\(displayName)')")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            self.currentSkin = next
            self.webView.loadHTMLString(self.petHTML(for: next), baseURL: nil)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.setValue(false, forKey: "drawsBackground")
        window.orderFront(nil)
    }

    func applicationWillTerminate(_ n: Notification) {
        refreshTimer?.invalidate()
        localMonitors.forEach { NSEvent.removeMonitor($0) }
    }
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
