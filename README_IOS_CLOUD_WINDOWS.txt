CAN LUA PRO V0.6.3 – IPA tren Mac Cloud tu Windows

1) Doc docs/TAO_IPA_GITHUB_WINDOWS.md
2) DAY MA NGUON: chay PUSH_GITHUB_WINDOWS.bat
3) TEST MIEN PHI KHONG CAN APPLE: GitHub -> Actions -> CAN LUA PRO V0.6.3 - IPA tren Mac Cloud -> Run workflow -> unsigned_check
4) TAO CERT TREN WINDOWS: APPLE_CHUNG_CHI_WINDOWS.bat
5) NHAP GITHUB SECRETS: IOS_BUNDLE_ID, APPLE_TEAM_ID, BUILD_CERTIFICATE_BASE64, P12_PASSWORD, BUILD_PROVISION_PROFILE_BASE64
6) TAO IPA: Run workflow -> signed_ipa
7) LAY IPA: Actions -> Artifacts -> CAN_LUA_PRO_V0.6.3_IOS_SIGNED_IPA
8) TESTFLIGHT: them 3 API Key secrets, chon signed_ipa_testflight

Khong co .ipa san trong goi. Chi co ma nguon, workflows, cong cu tao chung chi va tai lieu.
Khong gui khoa, chung chi Apple hay mat khau vao chat/issue.
