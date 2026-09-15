pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Emoji picker data (ChromeOS-style). Clicking an emoji copies it to the
 * clipboard (via wl-copy) — no key-injection tool needed. Recently used emoji
 * are persisted. Needs a colour emoji font (e.g. Noto Color Emoji) to render.
 */
Singleton {
    id: root

    // Each category: { name, icon (Material Symbol), items: [[emoji, "keywords"], ...] }
    readonly property var categories: [
        { name: "Smileys", icon: "mood", items: [
            ["😀","grin happy"],["😃","happy smile"],["😄","laugh happy"],["😁","grin"],
            ["😆","laugh"],["😅","sweat laugh"],["🤣","rofl"],["😂","joy tears"],
            ["🙂","smile"],["🙃","upside down"],["😉","wink"],["😊","blush"],
            ["😇","angel"],["🥰","love"],["😍","heart eyes"],["😘","kiss"],
            ["😜","tongue"],["🤪","zany"],["😝","tongue"],["🤗","hug"],
            ["🤔","think"],["🤨","raised brow"],["😐","neutral"],["😑","expressionless"],
            ["😴","sleep"],["😌","relieved"],["😏","smirk"],["🙄","eyeroll"],
            ["😬","grimace"],["😮","wow surprised"],["😯","hushed"],["😳","flushed"],
            ["🥺","pleading"],["😢","cry"],["😭","sob cry"],["😤","triumph"],
            ["😠","angry"],["😡","rage angry"],["🤯","mind blown"],["😱","scream"],
            ["😷","mask sick"],["🤒","sick"],["🤕","hurt"],["🥳","party"],
            ["😎","cool sunglasses"],["🤓","nerd"],["🥱","yawn"],["😈","devil"]
        ]},
        { name: "Gestures", icon: "front_hand", items: [
            ["👍","thumbs up like"],["👎","thumbs down"],["👌","ok"],["✌️","peace victory"],
            ["🤞","fingers crossed"],["🤟","love you"],["🤘","rock"],["👈","left"],
            ["👉","right"],["👆","up"],["👇","down"],["☝️","point up"],
            ["✋","hand stop"],["🤚","raised back"],["🖐️","hand"],["🖖","spock"],
            ["👋","wave hello hi"],["🤙","call me"],["💪","muscle strong"],["🙏","pray thanks please"],
            ["👏","clap"],["🙌","raised hands"],["👐","open hands"],["🤝","handshake deal"],
            ["✊","fist"],["👊","punch fist"],["❤️","heart love red"],["🧡","orange heart"],
            ["💛","yellow heart"],["💚","green heart"],["💙","blue heart"],["💜","purple heart"],
            ["🖤","black heart"],["🤍","white heart"],["💔","broken heart"],["💯","hundred perfect"]
        ]},
        { name: "Animals", icon: "pets", items: [
            ["🐶","dog puppy"],["🐱","cat"],["🐭","mouse"],["🐹","hamster"],
            ["🐰","rabbit bunny"],["🦊","fox"],["🐻","bear"],["🐼","panda"],
            ["🐨","koala"],["🐯","tiger"],["🦁","lion"],["🐮","cow"],
            ["🐷","pig"],["🐸","frog"],["🐵","monkey"],["🐔","chicken"],
            ["🐧","penguin"],["🐦","bird"],["🦆","duck"],["🦉","owl"],
            ["🐝","bee"],["🦋","butterfly"],["🐢","turtle"],["🐍","snake"],
            ["🐙","octopus"],["🐠","fish"],["🐬","dolphin"],["🐳","whale"],
            ["🦄","unicorn"],["🐴","horse"],["🌸","flower blossom"],["🌹","rose"],
            ["🌻","sunflower"],["🌲","tree"],["🌵","cactus"],["🍀","clover luck"]
        ]},
        { name: "Food", icon: "restaurant", items: [
            ["🍏","apple green"],["🍎","apple red"],["🍊","orange"],["🍋","lemon"],
            ["🍌","banana"],["🍉","watermelon"],["🍇","grapes"],["🍓","strawberry"],
            ["🫐","blueberry"],["🍒","cherry"],["🍑","peach"],["🥭","mango"],
            ["🍍","pineapple"],["🥥","coconut"],["🥝","kiwi"],["🍅","tomato"],
            ["🥑","avocado"],["🍔","burger"],["🍟","fries"],["🍕","pizza"],
            ["🌭","hotdog"],["🌮","taco"],["🍣","sushi"],["🍜","ramen noodles"],
            ["🍚","rice"],["🍞","bread"],["🧀","cheese"],["🍩","donut"],
            ["🍪","cookie"],["🍰","cake"],["🎂","birthday cake"],["🍫","chocolate"],
            ["🍿","popcorn"],["☕","coffee"],["🍵","tea"],["🍺","beer"]
        ]},
        { name: "Activities", icon: "sports_esports", items: [
            ["⚽","soccer football"],["🏀","basketball"],["🏈","football"],["⚾","baseball"],
            ["🎾","tennis"],["🏐","volleyball"],["🎱","pool"],["🏓","ping pong"],
            ["🏸","badminton"],["🥅","goal"],["🏒","hockey"],["🏑","field hockey"],
            ["🎯","dart target"],["🎳","bowling"],["🎮","game controller"],["🎲","dice"],
            ["🎸","guitar"],["🎹","piano"],["🎺","trumpet"],["🎻","violin"],
            ["🥁","drum"],["🎤","mic sing"],["🎧","headphones"],["🎬","movie"],
            ["🎨","art paint"],["🏆","trophy win"],["🥇","gold medal"],["🎉","party tada"],
            ["🎊","confetti"],["🎈","balloon"],["🎁","gift present"],["✨","sparkles"]
        ]},
        { name: "Travel", icon: "travel_explore", items: [
            ["🚗","car"],["🚕","taxi"],["🚙","suv"],["🚌","bus"],
            ["🏎️","race car"],["🚓","police"],["🚑","ambulance"],["🚒","fire truck"],
            ["🛵","scooter"],["🏍️","motorcycle"],["🚲","bike"],["✈️","plane"],
            ["🚀","rocket"],["🛸","ufo"],["🚁","helicopter"],["⛵","sailboat"],
            ["🚤","speedboat"],["🚂","train"],["🚆","train"],["🗺️","map"],
            ["🗿","statue"],["🗽","liberty"],["🏔️","mountain"],["🌋","volcano"],
            ["🏝️","island beach"],["🏖️","beach"],["🌅","sunrise"],["🌄","sunset"],
            ["🌉","bridge"],["🎡","ferris wheel"],["🎢","roller coaster"],["🏰","castle"]
        ]},
        { name: "Objects", icon: "lightbulb", items: [
            ["⌚","watch"],["📱","phone mobile"],["💻","laptop computer"],["⌨️","keyboard"],
            ["🖥️","desktop monitor"],["🖨️","printer"],["🖱️","mouse"],["💾","save disk"],
            ["💿","cd disc"],["📷","camera"],["📸","camera flash"],["🎥","video camera"],
            ["📺","tv"],["🔋","battery"],["🔌","plug"],["💡","idea bulb light"],
            ["🔦","flashlight"],["📖","book"],["📚","books"],["📝","memo note write"],
            ["✏️","pencil"],["🖊️","pen"],["📌","pin"],["📎","clip"],
            ["✂️","scissors cut"],["🔑","key"],["🔒","lock"],["🔓","unlock"],
            ["🔍","search magnify"],["💰","money bag"],["💵","dollar money"],["💳","card"]
        ]},
        { name: "Symbols", icon: "emoji_symbols", items: [
            ["✅","check tick done"],["❌","cross no wrong"],["❓","question"],["❗","exclaim"],
            ["⭐","star"],["🌟","glowing star"],["🔥","fire lit hot"],["⚡","lightning bolt"],
            ["💥","boom"],["💫","dizzy"],["💦","sweat drops"],["💤","zzz sleep"],
            ["🎵","music note"],["🎶","music notes"],["➕","plus add"],["➖","minus"],
            ["➗","divide"],["✖️","multiply"],["♻️","recycle"],["✔️","check"],
            ["🔴","red circle"],["🟠","orange circle"],["🟡","yellow circle"],["🟢","green circle"],
            ["🔵","blue circle"],["🟣","purple circle"],["⚫","black circle"],["⚪","white circle"],
            ["🚫","no ban"],["⚠️","warning"],["💬","speech bubble"],["👀","eyes look"]
        ]}
    ]

    // Recently used (persisted, newest first)
    property var recent: []
    readonly property string statePath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/quickshell-chrome/emoji_recent.json"

    function use(emoji) {
        Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", emoji]);
        const r = root.recent.filter(e => e !== emoji);
        r.unshift(emoji);
        if (r.length > 24) r.length = 24;
        root.recent = r;
        _save();
    }

    function search(q) {
        const s = (q || "").toLowerCase().trim();
        if (!s) return [];
        const out = [];
        for (const cat of root.categories)
            for (const it of cat.items)
                if (it[1].indexOf(s) !== -1) out.push(it[0]);
        return out;
    }

    function _save() {
        saveProc.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"$1\")\"; printf %s \"$2\" > \"$1\"",
            "sh", root.statePath, JSON.stringify(root.recent)];
        saveProc.running = true;
    }
    Process { id: saveProc }
    FileView {
        id: file
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                const a = JSON.parse(text() || "[]");
                if (Array.isArray(a)) root.recent = a;
            } catch (e) {}
        }
    }
    Component.onCompleted: file.reload()
}
