import urllib.request
import json
import ssl
import os

def translate_name_to_zh(name_en, category, target, equipment):
    name_lower = name_en.lower()
    
    # Exact or high-confidence common mappings
    exact_map = {
        "3/4 sit-up": "仰卧起坐 (3/4行程)",
        "barbell bench press": "杠铃平板卧推",
        "barbell incline bench press": "杠铃上斜卧推",
        "barbell decline bench press": "杠铃下斜卧推",
        "barbell full squat": "杠铃深蹲",
        "barbell deadlift": "杠铃硬拉",
        "pull-up": "标准引体向上",
        "chin-up": "反手引体向上",
        "dumbbell biceps curl": "哑铃二头交替弯举",
        "dumbbell lateral raise": "哑铃站姿侧平举",
        "dumbbell shoulder press": "坐姿哑铃推举",
        "cable triceps pushdown": "绳索三头肌下压",
        "cable seated row": "坐姿绳索划船",
        "push-up": "俯卧撑",
        "dips": "双杠臂屈伸",
        "plank": "平板支撑",
        "hanging leg raise": "悬垂举腿",
        "romanian deadlift": "罗马尼亚硬拉",
        "bulgarian split squat": "保加利亚分腿蹲",
        "lat pulldown": "高位下拉",
        "face pull": "绳索面拉"
    }
    if name_lower in exact_map:
        return exact_map[name_lower]
        
    # Dictionary word replacements for translation construction
    parts = []
    
    # Equip prefixes
    equip_terms = {
        "barbell": "杠铃",
        "dumbbell": "哑铃",
        "cable": "绳索",
        "kettlebell": "壶铃",
        "band": "弹力带",
        "resistance band": "弹力带",
        "smith": "史密斯",
        "machine": "固定器械",
        "lever": "器械",
        "ez barbell": "曲杆杠铃",
        "weighted": "负重",
        "bodyweight": "自重"
    }
    
    pos_terms = {
        "incline": "上斜",
        "decline": "下斜",
        "seated": "坐姿",
        "standing": "站姿",
        "lying": "仰卧",
        "prone": "俯卧",
        "hanging": "悬垂",
        "alternating": "交替",
        "single leg": "单腿",
        "single arm": "单臂",
        "one arm": "单臂",
        "reverse": "反向",
        "close grip": "窄握",
        "wide grip": "宽握"
    }
    
    action_terms = {
        "bench press": "平板卧推",
        "chest press": "胸部推举",
        "shoulder press": "肩部推举",
        "overhead press": "头顶推举",
        "press": "推举",
        "squat": "深蹲",
        "deadlift": "硬拉",
        "lunge": "箭步蹲",
        "split squat": "分腿蹲",
        "curl": "二头弯举",
        "preacher curl": "牧师凳弯举",
        "hammer curl": "锤式弯举",
        "extension": "臂屈伸",
        "triceps extension": "三头肌伸展",
        "pushdown": "下压",
        "pulldown": "下拉",
        "lat pulldown": "高位下拉",
        "row": "划船",
        "bent-over row": "俯身划船",
        "raise": "平举",
        "lateral raise": "侧平举",
        "front raise": "前平举",
        "fly": "夹胸/飞鸟",
        "reverse fly": "反向飞鸟",
        "shrug": "耸肩",
        "crunch": "卷腹",
        "sit-up": "仰卧起坐",
        "twist": "转体",
        "russian twist": "俄罗斯转体",
        "leg raise": "举腿",
        "calf raise": "提踵",
        "dip": "臂屈伸",
        "pull-up": "引体向上"
    }
    
    # Construct translation
    zh_str = ""
    for k, v in equip_terms.items():
        if k in name_lower:
            zh_str += v
            break
            
    for k, v in pos_terms.items():
        if k in name_lower:
            zh_str += v
            break
            
    found_action = False
    # Sort action terms by length descending to match longest phrase first
    for k in sorted(action_terms.keys(), key=lambda x: len(x), reverse=True):
        if k in name_lower:
            zh_str += action_terms[k]
            found_action = True
            break
            
    if not found_action or len(zh_str) == 0:
        # Fallback using English cleaned + target muscle guidance
        return f"{zh_str} ({name_en.title()})" if len(zh_str) > 0 else name_en.title()
        
    return zh_str

def get_calibration(name_en, category, equipment):
    name_lower = name_en.lower()
    cat_lower = category.lower()
    
    # Defaults
    dominant_axis = 1 # rotY (pitch)
    min_ratio = 0.35
    threshold_g = "+0.55g"
    motion_profile = "upperBodyPull"
    rest_seconds = 60
    
    # Lateral / Fly / Roll movements -> dominantAxis = 0 (rotX)
    if any(x in name_lower for x in ["fly", "lateral raise", "side raise", "front raise", "around the world", "straight arm", "cuban"]):
        dominant_axis = 0
        min_ratio = 0.32
        threshold_g = "+0.40g"
        motion_profile = "lateralOrCore"
        rest_seconds = 60
    # Core yaw / twisting / hanging -> dominantAxis = 2 (rotZ)
    elif any(x in name_lower for x in ["twist", "russian", "woodchopper", "wiper", "hanging", "leg raise"]) or cat_lower == "waist":
        dominant_axis = 2
        min_ratio = 0.30
        threshold_g = "+0.35g"
        motion_profile = "lateralOrCore"
        rest_seconds = 45
    # Lower body compound -> dominantAxis = 1
    elif cat_lower in ["upper legs", "lower legs"] or any(x in name_lower for x in ["squat", "deadlift", "lunge", "leg press", "calf", "thrust"]):
        dominant_axis = 1
        min_ratio = 0.28
        threshold_g = "+0.80g" if "squat" in name_lower or "deadlift" in name_lower or "press" in name_lower else "+0.50g"
        motion_profile = "lowerBodyCompound"
        rest_seconds = 90 if "squat" in name_lower or "deadlift" in name_lower else 60
    # Upper body press -> dominantAxis = 1
    elif any(x in name_lower for x in ["bench press", "chest press", "shoulder press", "overhead press", "push-up", "dip"]):
        dominant_axis = 1
        min_ratio = 0.35
        threshold_g = "+0.65g" if "barbell" in name_lower else "+0.55g"
        motion_profile = "upperBodyPress"
        rest_seconds = 75
    # Upper body pull / arms -> dominantAxis = 1
    elif any(x in name_lower for x in ["row", "pull-up", "pulldown", "curl", "extension", "pushdown", "shrug"]):
        dominant_axis = 1
        min_ratio = 0.37
        threshold_g = "+0.50g"
        motion_profile = "upperBodyPull"
        rest_seconds = 60
        
    return dominant_axis, min_ratio, threshold_g, motion_profile, rest_seconds

def main():
    ctx = ssl._create_unverified_context()
    url = "https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/data/exercises.json"
    print("Downloading exercises.json from GitHub...")
    raw_data = urllib.request.urlopen(url, context=ctx).read().decode("utf-8")
    data = json.loads(raw_data)
    print(f"Loaded {len(data)} exercises. Processing...")
    
    category_map = {
        "chest": ("胸部", "Chest", "X"),
        "back": ("背部", "Back", "B"),
        "shoulders": ("肩部", "Shoulders", "Y"),
        "upper arms": ("手臂", "Upper Arms", "A"),
        "lower arms": ("前臂", "Lower Arms", "A"),
        "upper legs": ("大腿", "Upper Legs", "L"),
        "lower legs": ("小腿", "Lower Legs", "L"),
        "waist": ("腹部核心", "Core/Waist", "C"),
        "cardio": ("有氧心肺", "Cardio", "O"),
        "neck": ("颈部功能", "Neck", "O")
    }
    
    equip_map = {
        "body weight": ("自重", "Body Weight"),
        "barbell": ("杠铃", "Barbell"),
        "dumbbell": ("哑铃", "Dumbbell"),
        "cable": ("绳索/拉力器", "Cable"),
        "leverage machine": ("固定器械", "Machine"),
        "smith machine": ("史密斯机", "Smith Machine"),
        "band": ("弹力带", "Resistance Band"),
        "kettlebell": ("壶铃", "Kettlebell"),
        "weighted": ("负重自重", "Weighted"),
        "stability ball": ("健身球", "Stability Ball"),
        "ez barbell": ("曲杆杠铃", "EZ Barbell"),
        "other": ("其他辅助", "Other")
    }
    
    processed_list = []
    for item in data:
        ex_id = item.get("id", "0000")
        name_en = item.get("name", "").strip()
        cat_raw = item.get("category", "other").lower()
        equip_raw = item.get("equipment", "other").lower()
        target_raw = item.get("target", "").lower()
        
        cat_zh, cat_en, badge = category_map.get(cat_raw, ("全身及其他", cat_raw.title(), "O"))
        equip_zh, equip_en = equip_map.get(equip_raw, ("其他器械", equip_raw.title()))
        
        name_zh = translate_name_to_zh(name_en, cat_raw, target_raw, equip_raw)
        
        # Instructions & steps
        inst_dict = item.get("instructions", {})
        inst_zh = inst_dict.get("zh", "").strip()
        inst_en = inst_dict.get("en", "").strip()
        
        steps_dict = item.get("instruction_steps", {})
        steps_zh = steps_dict.get("zh", [])
        steps_en = steps_dict.get("en", [])
        
        if not inst_zh and steps_zh:
            inst_zh = " ".join(steps_zh)
        if not inst_en and steps_en:
            inst_en = " ".join(steps_en)
        if not inst_zh:
            inst_zh = f"【{cat_zh} / {equip_zh}动作】保持核心稳定与良好发力姿势，平稳控制动作节奏。"
        if not inst_en:
            inst_en = f"Maintain good posture and core engagement throughout this {cat_en} exercise using {equip_en}."
            
        gif_url = "https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/" + item.get("gif_url", "")
        img_url = "https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/" + item.get("image", "")
        
        dom_axis, min_ratio, threshold_g, motion_prof, rest_sec = get_calibration(name_en, cat_raw, equip_raw)
        
        processed_list.append({
            "id": ex_id,
            "nameZh": name_zh,
            "nameEn": name_en.title(),
            "categoryZh": f"{cat_zh} ({cat_en})",
            "categoryEn": cat_en,
            "descriptionZh": inst_zh,
            "descriptionEn": inst_en,
            "stepsZh": steps_zh if steps_zh else [inst_zh],
            "stepsEn": steps_en if steps_en else [inst_en],
            "equipmentZh": equip_zh,
            "equipmentEn": equip_en,
            "targetZh": target_raw.title(),
            "targetEn": target_raw.title(),
            "restSeconds": rest_sec,
            "thresholdG": threshold_g,
            "badgeLetter": badge,
            "dominantAxis": dom_axis,
            "minRatio": min_ratio,
            "motionProfile": motion_prof,
            "gifUrl": gif_url,
            "imageUrl": img_url
        })
        
    print(f"Processed {len(processed_list)} exercises. Writing JSON file...")
    out_path = "/Users/a171325./Documents/新构建版软件/SimpleFitness/exercises_database.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(processed_list, f, ensure_ascii=False, indent=1)
    print(f"Successfully wrote {len(processed_list)} items to {out_path} ({os.path.getsize(out_path)/1024:.1f} KB)")

if __name__ == "__main__":
    main()
