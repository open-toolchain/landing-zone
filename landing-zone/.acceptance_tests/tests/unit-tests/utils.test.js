const { assert } = require("chai");
const tfUnitTestUtils = require("../utils/utils.js");

const tfutils = new tfUnitTestUtils("./plan_test.sh", "../defaults");
process.env.API_KEY = "apikey";

describe("tfUnitTestUtils", () => {
  describe("getPlanJson", () => {
    let lastRunScript;
    const mockExec = async function (script) {
      lastRunScript = script;
      return {
        stdout: `{"planned_values":true}`,
      };
    };
    const mockExecErr = async function (script) {
      throw new Error("this is a mock error");
    };
    it("should return the proper planned values when a script is called", async () => {
      let actualValue = await tfutils.getPlanJson(mockExec);
      assert.deepEqual(
        actualValue,
        true,
        "should return parsed json for plan values `true`"
      );
    });
    it("should run the correct bash script", async () => {
      let run = await tfutils.getPlanJson(mockExec);
      let actualValue = lastRunScript;
      let expectedValue = `sh ./plan_test.sh apikey ../defaults`;
      assert.deepEqual(
        actualValue,
        expectedValue,
        "should run the correct bash code"
      );
    });
    it("should throw an error is the JSON parse fails", async() => {
        await tfutils.getPlanJson(mockExecErr).catch(err => {
            assert.deepEqual(err.message, "this is a mock error")
        })
    });
  });
});
