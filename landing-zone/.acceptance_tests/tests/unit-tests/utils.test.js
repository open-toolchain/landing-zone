const { assert } = require("chai");
const tfUnitTestUtils = require("../utils/utils.js");
const tfutils = new tfUnitTestUtils("./plan_test.sh", "../defaults");

describe("tfUnitTestUtils", () => {
    describe("getPlanJson", () => {
        const mockExec = async function(script) {
            return {
                stdout: `{"planned_values":true}`
            }
        }
        it("should return the proper planned values when a script is called", async() => {
            let actualValue = await tfutils.getPlanJson(mockExec)
            assert.deepEqual(actualValue, true, "should return parsed json for plan values `true`")
        })
    })
})