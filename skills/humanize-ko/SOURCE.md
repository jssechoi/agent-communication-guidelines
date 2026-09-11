# Source

- **Upstream**: https://github.com/jssechoi/materials, path `claude-skills/humanize-ko/SKILL.md`
- **Author**: jssechoi. Same author as this repository.
- **License**: MIT, together with the rest of this repository. See `LICENSE` at the repository
  root.
- **Copied on**: 2026-08-19

The copy in `materials` stays the editing target so a single change does not have to be made twice.
Fix the rule there, then overwrite this file. Editing only this copy leaves the two versions out of
step.

`humanizer` covers English patterns (em dash, "delve", inflated symbolism) and catches roughly half
of what shows up in Korean. This skill covers the rest: translationese particles, uniform `-습니다`
endings, service-desk politeness. Both apply to Korean prose. Overlapping items (rule of three,
bold overuse, emoji) are fixed once.

## 줄바꿈

이 저장소는 CRLF 입니다. `materials` 의 원본은 LF 이므로 복사한 뒤 줄바꿈을 맞춥니다. 맞추지
않으면 diff 가 전 줄 재작성으로 잡힙니다.

```bash
sed -i 's/\r*$/\r/' skills/humanize-ko/SKILL.md
```
