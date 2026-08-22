import 'dart:convert';

import 'package:metaphysics_core/enums.dart';
import 'package:flutter/material.dart';
import 'package:repository_contract_kernel/repository_contract_kernel.dart';
import 'package:repository_interface_qimendunjia/repository_interface_qimendunjia.dart';
import 'package:qimendunjia/enums/enum_eight_door.dart';
import 'package:qimendunjia/enums/enum_nine_stars.dart';
import 'package:qimendunjia/model/door_star_ke_ying.dart';
import 'package:qimendunjia/model/qi_yi_ru_gong.dart';
import 'package:qimendunjia/model/ten_gan_ke_ying.dart';

import '../model/eight_door_ke_ying.dart';
import '../model/ten_gan_ke_ying_ge_ju.dart';

/// Parses the Qimendunjia official rule JSON into domain models.
///
/// Storage-agnostic: it obtains the raw JSON strings from an injected
/// [QimendunjiaOfficialRuleRepository] port (see repository_interface_qimendunjia).
/// It performs NO direct asset access; the asset backend
/// lives in `persistence_assets` and is wired by the host (`ServiceLocator`).
class ReadDataUtils {
  final QimendunjiaOfficialRuleRepository _officialRules;

  ReadDataUtils(this._officialRules);

  RequestContext get _ctx => RequestContext(scopeUid: 'local-anonymous');

  Future<String> _readRule(String id) async {
    final res = await _officialRules.get(id, _ctx);
    return res.orElse('') ?? '';
  }

  Future<Map<TianGan, Map<TianGan, TenGanKeYing>>> readTenGanKeYing() async {
    try {
      String jsonString = await _readRule("ten_gan_ke_ying");
      Map<String, dynamic> jsonMapper = jsonDecode(jsonString);
      Map<TianGan, Map<TianGan, TenGanKeYing>> result = {};
      for (var key in jsonMapper.keys) {
        Map<TianGan, TenGanKeYing> res = {};
        Map<String, dynamic> value = jsonMapper[key]!;
        if (key == "甲") {
          for (var k in value.keys) {
            res[TianGan.getFromValue(k)!] = TenGanKeYing.fromJson(value[k]);
          }
          result[TianGan.JIA] = res;
        } else {
          for (var k in value.keys) {
            if (k == "甲") {
              res[TianGan.JIA] = TenGanKeYing.fromJson(value[k]);
            } else {
              res[TianGan.getFromValue(k)!] = TenGanKeYing.fromJson(value[k]);
            }
          }
          result[TianGan.getFromValue(key)!] = res;
        }
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<TianGan, Map<TianGan, TenGanKeYingGeJu>>>
      readTenGanKeYingGeJu() async {
    final content = await _readRule("ten_gan_ge_ju");
    Map<String, dynamic> jsonMapper2 = jsonDecode(content);
    Map<TianGan, Map<TianGan, TenGanKeYingGeJu>> finalResult = {};
    for (var key in jsonMapper2.keys) {
      TianGan tian = TianGan.getFromValue(key)!;
      if (!finalResult.containsKey(tian)) {
        finalResult[tian] = {};
      }
      for (var k in jsonMapper2[key]!.keys) {
        TianGan di = TianGan.getFromValue(k)!;
        finalResult[tian]![di] = TenGanKeYingGeJu.fromJson(jsonMapper2[key][k]);
      }
    }
    return finalResult;
  }

  Future<Map<TianGan, Map<TianGan, TenGanKeYing>>>
      readTenGanKeYingJiXiong(BuildContext context) async {
    try {
      String jsonString = await _readRule("ten_gan_ke_ying");
      Map<String, dynamic> jsonMapper = jsonDecode(jsonString);
      Map<TianGan, Map<TianGan, TenGanKeYing>> result = {};
      for (var key in jsonMapper.keys) {
        Map<TianGan, TenGanKeYing> res = {};
        Map<String, dynamic> value = jsonMapper[key]!;
        if (key == "甲") {
          for (var k in value.keys) {
            res[TianGan.getFromValue(k)!] = TenGanKeYing.fromJson(value[k]);
          }
          result[TianGan.JIA] = res;
        } else {
          for (var k in value.keys) {
            if (k == "甲") {
              res[TianGan.JIA] = TenGanKeYing.fromJson(value[k]);
            } else {
              res[TianGan.getFromValue(k)!] = TenGanKeYing.fromJson(value[k]);
            }
          }
          result[TianGan.getFromValue(key)!] = res;
        }
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<EightDoorEnum, Map<TianGan, String>>> readDoorGanKeYing() async {
    final content = await _readRule("door_gan_ke_ying");
    Map<String, dynamic> jsonMapper = jsonDecode(content);
    Map<EightDoorEnum, Map<TianGan, String>> result = {};
    for (var key in jsonMapper.keys) {
      Map<TianGan, String> res = {};
      Map<String, dynamic> value = jsonMapper[key]!;
      for (var k in value.keys) {
        res[TianGan.getFromValue(k)!] = value[k];
      }
      result[EightDoorEnum.fromSingleCharName(key)] = res;
    }
    return result;
  }

  Future<Map<HouTianGua, Map<TianGan, QiYiRuGong>>> readQiYiRuGong() async {
    final content = await _readRule("qi_yi_ru_gong");
    Map<String, dynamic> jsonMapper = jsonDecode(content);
    Map<HouTianGua, Map<TianGan, QiYiRuGong>> result = {};
    for (var key in jsonMapper.keys) {
      Map<TianGan, QiYiRuGong> res = {};
      Map<String, dynamic> value = jsonMapper[key]!;
      HouTianGua gongName = HouTianGua.getGuaByName(key);
      for (var k in value.keys) {
        Map<String, dynamic> tmp = Map.from(value[k]);
        TianGan currentGan = TianGan.getFromValue(k)!;
        tmp["qiYi"] = currentGan.name;
        tmp["gong"] = gongName.name;
        try {
          res[currentGan] = QiYiRuGong.fromJson(tmp);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      result[gongName] = res;
    }
    return result;
  }

  Future<Map<HouTianGua, Map<TianGan, String>>> readQiYiRuGongDisease() async {
    final content = await _readRule("qi_yi_ru_gong_disease");
    Map<String, dynamic> jsonMapper = jsonDecode(content);
    Map<HouTianGua, Map<TianGan, String>> result = {};
    for (var key in jsonMapper.keys) {
      if (key == "中") {
        continue;
      }
      Map<TianGan, String> res = {};
      Map<String, dynamic> value = jsonMapper[key]!;
      for (var k in value.keys) {
        res[TianGan.getFromValue(k)!] = value[k];
      }
      result[HouTianGua.getGuaByName(key)] = res;
    }
    return result;
  }

  Future<Map<EightDoorEnum, Map<NineStarsEnum, DoorStarKeYing>>>
      readDoorStarKeYing() async {
    final content = await _readRule("door_star_ke_ying");
    Map<String, dynamic> jsonMapper = jsonDecode(content);
    Map<EightDoorEnum, Map<NineStarsEnum, DoorStarKeYing>> result = {};
    List<DoorStarKeYing> resultList = [];
    for (var key in jsonMapper.keys) {
      Map<String, dynamic> value = jsonMapper[key]!;
      for (var k in value.keys) {
        Map<String, dynamic> vMapper = value[k];
        vMapper["door"] = k;
        vMapper["star"] = key;
        resultList.add(DoorStarKeYing.fromJson(vMapper));
      }
    }
    for (var e in resultList) {
      if (!result.keys.contains(e.door)) {
        result[e.door] = {};
      }
      result[e.door]![e.star] = e;
    }
    return result;
  }

  Future<Map<EightDoorEnum, Map<EightDoorEnum, Map<YinYang, EightDoorKeYing>>>>
      readEightDoorKeYing() async {
    final content = await _readRule("eight_door_ke_ying");
    try {
      Map<String, dynamic> jsonMapper = jsonDecode(content);
      List<EightDoorKeYing> resultList = [];
      for (var key in jsonMapper.keys) {
        Map<String, dynamic> value = jsonMapper[key]!;
        for (var k1 in value.keys) {
          Map<String, dynamic> vMapper = value[k1];
          for (var k2 in vMapper.keys) {
            String content = vMapper[k2];
            resultList.add(EightDoorKeYing.fromJson({
              "fixDoor": k2,
              "door": key,
              "dongJingYing": k1 == "静应" ? "阴" : "阳",
              "description": content,
            }));
          }
        }
      }
      Map<EightDoorEnum, Map<EightDoorEnum, Map<YinYang, EightDoorKeYing>>>
          result = {};
      for (var e in resultList) {
        if (!result.keys.contains(e.door)) {
          result[e.door] = {};
        }
        if (!result[e.door]!.keys.contains(e.fixDoor)) {
          result[e.door]![e.fixDoor] = {};
        }
        result[e.door]![e.fixDoor]![e.dongJingYing] = e;
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
